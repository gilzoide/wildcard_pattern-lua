local wildcard_pattern = {}

local scanner = {
    -- simple substitution
    ['%'] = function(state) return  "%%", 1 end,
    ['.'] = function(state) return  "%.", 1 end,
    ['('] = function(state) return  "%(", 1 end,
    [')'] = function(state) return  "%)", 1 end,
    ['+'] = function(state) return  "%+", 1 end,
    ['?'] = function(state) return "[^/]", 1 end,
    -- glob
    ['*'] = function(state)
        if state.following == '*' then
            return '.*', 2
        else
            return '[^/]*', 1
        end
    end,
    -- character set and ranges
    ['['] = function(state)
        state.in_brackets = true
        if state.following == '!' then
            return '[^', 2
        elseif state.following == '-' then
            return '[%-', 2
        else
            return '[', 1
        end
    end,
    [']'] = function(state)
        state.in_brackets = false
        return ']', 1
    end,
    ['-'] = function(state)
        return state.in_brackets and state.following ~= ']' and '-' or '%-', 1
    end,
    ['\\'] = function(state)
        local following = state.following
        return following:match('%w') and following or '%' .. following, 2
    end,

}
--- Create a Lua pattern from wildcard.
--
-- Escapes:
--   '%' -> '%%'
--   '.' -> '%.'
--   '(' -> '%('
--   ')' -> '%)'
--   '+' -> '%+'
--   '-' -> '%-' (unless inside range like [0-9])
-- Unescape:
--   '\' -> '%'
-- Substitutions:
--   '?'  -> '[^/]'
--   '**' -> '.*'
--   '*'  -> '[^/]*'
--   '[!' -> '[^'
--
-- @tparam string s Wildcard string
-- @param[opt] anchor_to_slash If truthy, anchor pattern to directory separators instead of to the begining of `s`
--
-- @treturn string Lua pattern corresponding to given wildcard
function wildcard_pattern.from_wildcard(s, anchor_to_slash)
    local init, state, current = 1, {}
    while true do
        local next_special_pos = s:find("[%%%.()+%-\\?*%[%]]", init)
        local copy_verbatim = s:sub(init, (next_special_pos and next_special_pos - 1))
        if copy_verbatim ~= '' then
            table.insert(state, copy_verbatim)
        end
        if not next_special_pos then break end
        current, state.following = s:sub(next_special_pos, next_special_pos), s:sub(next_special_pos + 1, next_special_pos + 1)
        local insert, advance = scanner[current](state)
        table.insert(state, insert)
        init = next_special_pos + advance
    end
    local pattern = table.concat(state)
    local anchor = anchor_to_slash and '%f[/]' or '^'
    return anchor .. pattern .. '$'
end

--- Try matching `s` to every pattern in `t`, returning `s` if any match occurs
--
-- @treturn[1] string `s`, if there was a match
-- @return[2] `false` if `s` didn't match any pattern in `t`
function wildcard_pattern.any_match(t, s)
    for i, patt in ipairs(t) do
        local m = s:match(patt)
        if m then
            return s
        end
    end
    return false
end

--- Create a table with Lua patterns from a gitignore-like content.
--
-- @param contents String, line iterator function (e.g., `io.lines(...)`),
--                 or a table or userdata containing a `lines` method (e.g., files).
function wildcard_pattern.from_ignore(contents, comment_prefix)
    local content_type, line_iterator = type(contents)
    if content_type == 'string' then
        line_iterator = string.gmatch(contents, "[^\n]*")
    elseif content_type == 'table' or content_type == 'userdata' then
        line_iterator = content_type.lines and content_type:lines()
        if not line_iterator then
            return nil, string.format("Couldn't find a `lines` method in given %s", content_type)
        end
    elseif content_type == 'function' then
        line_iterator = contents
    else
        return nil, string.format("Expected contents be a string, table, userdata or function, found %s", content_type)
    end

    comment_prefix = comment_prefix or '#'
    local comment_prefix_length = #comment_prefix
    local t = {}
    for line in line_iterator do
        if line:sub(1, comment_prefix_length) ~= comment_prefix then
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed ~= '' then
                table.insert(t, wildcard_pattern.from_wildcard(trimmed, trimmed:find("/.", 1, true)))
            end
        end
    end
    return t
end

return wildcard_pattern
