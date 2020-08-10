local wildcard_pattern = {}

local function sub_question_mark(prefix, s)
    if prefix == '\\' then
        return '%?'
    else
        return '[^/]'
    end
end
local function sub_star(prefix, s)
    if prefix == '\\' then
        return '%*' .. sub_star('', s:sub(2))
    elseif #s == 0 then
        return ''
    elseif #s == 1 then
        return "[^/]*"
    else
        return ".*"
    end
end
local function sub_backslash(s)
    if s:match('%w') then
        return s
    else
        return '%' .. s
    end
end
--- Create a Lua pattern from wildcard.
--
-- Escapes:
--   '%' -> '%%'
--   '.' -> '%.'
--   '(' -> '%('
--   ')' -> '%)'
--   '+' -> '%+'
--   '-' -> '%-'
-- Unescape:
--   '\' -> '%'
-- Substitutions:
--   '?'  -> '[^/]'
--   '**' -> '.*'
--   '*'  -> '[^/]*'
--   '[!' -> '[^'
function wildcard_pattern.from_wildcard(s, unanchored)
    s = s:gsub('[%%%.%(%)+-]', '%%%0')
    s = s:gsub('([^?]?)%?', sub_question_mark)
        :gsub('([^*]?)(%*+)', sub_star)
        :gsub('%[!', '[%^')
        :gsub('\\(.)', sub_backslash)
    if not unanchored then
        s = '^' .. s .. '$'
    end
    return s
end

function wildcard_pattern.aggregate(...)
    
end

return wildcard_pattern
