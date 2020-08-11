local wildcard_pattern = {}

local scanner = {
    -- simple substitution
    ['%'] = function(state) return  "%%", 1 end,
    ['.'] = function(state) return  "%.", 1 end,
    ['('] = function(state) return  "%(", 1 end,
    [')'] = function(state) return  "%)", 1 end,
    ['+'] = function(state) return  "%+", 1 end,
    ['?'] = function(state) return "[^/]", 1 end,
    -- star patterns
    ['*'] = function(state)
        local double_asterisk, trailing_slash = state.following:match("(%*)(/?)")
        if trailing_slash == '/' then
            return '.*%f[^%z/]', 3
        elseif double_asterisk then
            return '.*', 2
        else
            return '[^/]*', 1
        end
    end,
    -- character set and ranges
    ['['] = function(state)
        state.in_brackets = true
        local following = state.following:sub(1, 1)
        if following == '!' then
            return '[^', 2
        elseif following == '-' then
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
        return state.in_brackets and state.following:sub(1, 1) ~= ']' and '-' or '%-', 1
    end,
    ['\\'] = function(state)
        local following = state.following:sub(1, 1)
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
-- @param[opt] anchor_to_slash If truthy, anchor pattern to optional directory separator '/' instead of to the begining of `s`
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
        current, state.following = s:sub(next_special_pos, next_special_pos), s:sub(next_special_pos + 1)
        local insert, advance = scanner[current](state)
        table.insert(state, insert)
        init = next_special_pos + advance
    end
    local pattern = table.concat(state)
    local anchor = anchor_to_slash and '%f[^%z/]' or '^'
    return anchor .. pattern .. '$'
end

--- Try matching `s` to every pattern in `t`, returning `s` if any match occurs
--
-- @treturn[1] string `s`, if there was a match
-- @return[2]  `false` if `s` didn't match any pattern in `t`
function wildcard_pattern.any_match(t, s)
    for i, patt in ipairs(t) do
        if s:match(patt) then
            return s
        end
    end
    return false
end

--- Metatable for aggregate patterns, e.g., from gitignore-like files
local wildcard_aggregate_mt = {}

--- Create a new aggregate pattern table
function wildcard_aggregate_mt.new()
    return setmetatable({}, wildcard_aggregate_mt)
end

--- Insert a wildcard in an aggregate pattern table
-- 
-- @treturn[1] string The generated pattern
-- @treturn[2] nil    If line is not empty nor a comment (leading '#')
function wildcard_aggregate_mt:insert(line)
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed ~= '' and trimmed:sub(1, 1) ~= '#' then
        local slash_pos, anchor_to_slash = trimmed:find('/', 1, true), false
        if slash_pos == 1 then
            trimmed = trimmed:sub(2)
        else
            anchor_to_slash = true
        end
        local pattern = wildcard_pattern.from_wildcard(trimmed, anchor_to_slash)
        table.insert(self, pattern)
        return pattern
    end
end

--- Facility to inserting several wildcards in a single call
function wildcard_aggregate_mt:extend(...)
    for i = 1, select('#', ...) do
        local wildcard = select(i, ...)
        self:insert(wildcard)
    end
end

--- Remove a pattern from an aggregate pattern table
wildcard_aggregate_mt.remove = table.remove

--- Gets a line iterator function from `contents`
--
-- @param contents String, line iterator function (e.g., `io.lines(...)` or `file:lines()`),
--                 or a table or userdata containing a `lines` method (e.g., files).
-- 
-- @treturn[1] function Line iterator
-- @treturn[2] nil
-- @treturn[2] string Error message if iterator could not be generated
local function line_iterator_from(contents)
    local content_type, line_iterator = type(contents)
    if content_type == 'function' then
        line_iterator = contents
    elseif content_type == 'string' then
        line_iterator = string.gmatch(contents, "[^\n]*")
    elseif content_type == 'table' or content_type == 'userdata' then
        line_iterator = contents.lines and contents:lines()
        if not line_iterator then
            return nil, string.format("Couldn't find a `lines` method in given %s", content_type)
        end
    else
        return nil, string.format("Expected contents be a string, table, userdata or function, found %s", content_type)
    end
    return line_iterator
end

--- Extend an aggregate pattern table with wildcards from gitignore-like file content.
--
-- @param contents String, line iterator function (e.g., `io.lines(...)` or `file:lines()`),
--                 or a table or userdata containing a `lines` method (e.g., files).
function wildcard_aggregate_mt:extend_from(contents)
    local line_iterator, err = line_iterator_from(contents)
    if not line_iterator then
        return nil, err
    end

    for line in line_iterator do
        self:insert(line)
    end
end

--- Create an aggregate pattern table from gitignore-like content.
--
-- @param contents String, line iterator function (e.g., `io.lines(...)` or `file:lines()`),
--                 or a table or userdata containing a `lines` method (e.g., files).
-- @return Aggregate pattern table
function wildcard_aggregate_mt.from(contents)
    local line_iterator, err = line_iterator_from(contents)
    if not line_iterator then
        return nil, err
    end

    comment_prefix = comment_prefix or '#'
    local comment_prefix_length = #comment_prefix
    local t = wildcard_aggregate_mt.new()
    t:extend_from(line_iterator)
    return t
end

wildcard_aggregate_mt.__index = {
    insert = wildcard_aggregate_mt.insert,
    extend = wildcard_aggregate_mt.extend,
    extend_from = wildcard_aggregate_mt.extend_from,
    remove = wildcard_aggregate_mt.remove,
    any_match = wildcard_pattern.any_match,
}
wildcard_aggregate_mt.__call = wildcard_pattern.any_match

wildcard_pattern.aggregate = wildcard_aggregate_mt

wildcard_pattern._VERSION = '1.0.0'

return wildcard_pattern
