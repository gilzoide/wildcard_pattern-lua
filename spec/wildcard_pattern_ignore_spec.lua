local wildcard_pattern = require 'wildcard_pattern'

local function import_file(path)
    local file = assert(io.open(path))
    local result = assert(wildcard_pattern.from_ignore(file))
    file:close()
    return result
end

local function import_text(path)
    local file = assert(io.open(path))
    local text = file:read('*a')
    file:close()
    return wildcard_pattern.from_ignore(text)
end

local function import_iterator(path)
    local iterator = io.lines(path)
    return wildcard_pattern.from_ignore(iterator)
end

it("Importing ignore files from any approach yields the same aggregated patterns", function()
    local from_file = import_file('.gitignore')
    assert.are.equal('table', type(from_file))
    local from_text = import_text('.gitignore')
    assert.are.equal('table', type(from_text))
    local from_iterator = import_iterator('.gitignore')
    assert.are.equal('table', type(from_iterator))

    assert.are.same(from_file, from_text)
    assert.are.same(from_file, from_iterator)
    assert.are.same(from_text, from_iterator)
end)

-------------------------------------------------------------------------------
local ignore = wildcard_pattern.from_ignore([[
# This is a test ignore file
*.md
/from-root-only
]])

local function should_match(path)
    assert.is_truthy(wildcard_pattern.any_match(ignore, path))
end
local function should_not_match(path)
    assert.is_falsy(wildcard_pattern.any_match(ignore, path))
end

describe("Patterns from ignore files", function()
    it("match in any directory depth if '/' is not found in it", function()
        should_match("README.md")
        should_match("tutorial/1-Getting-started.md")
    end)

    it("match only from current directory with a leading '/'", function()
        should_match("from-root-only")
        should_not_match("tutorial/from-root-only")
    end)
end)
