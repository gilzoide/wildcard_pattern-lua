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
--   '?'  -> '.'
--   '**' -> '.*'
--   '*'  -> '[^/]*'
--   '[!' -> '[^'
function wildcard_pattern.from_wildcard(s)
    s = s:gsub('[%%%.%(%)+-]', '%%%0')
    s = s:gsub('\\(.)', '%%%1')
    s = s:gsub('%?', '.'):gsub('%*%*', '.*'):gsub('%*', '[^/]*')
    return '^' .. s .. '$'
end

return wildcard_pattern
