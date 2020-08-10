local wildcard_pattern = {}

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
local function sub_star(s)
    if #s == 1 then
        return "[^/]*"
    else
        return ".*"
    end
end
function wildcard_pattern.from_wildcard(s, unanchored)
    s = s:gsub('[%%%.%(%)+-]', '%%%0')
    s = s:gsub('\\(.)', '%%%1')
    s = s:gsub('%?', '[^/]'):gsub('%*+', sub_star):gsub('%[!', '[%^')
    if not unanchored then
        s = '^' .. s .. '$'
    end
    return s
end

function wildcard_pattern.aggregate(...)
    
end

return wildcard_pattern
