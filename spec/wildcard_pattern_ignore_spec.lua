local wildcard_pattern = require 'wildcard_pattern'

local function import_file(path)
    local file = assert(io.open(path))
    local result = assert(wildcard_pattern.aggregate.from(file))
    file:close()
    return result
end

local function import_text(path)
    local file = assert(io.open(path))
    local text = file:read('*a')
    file:close()
    return wildcard_pattern.aggregate.from(text)
end

local function import_iterator(path)
    local iterator = io.lines(path)
    return wildcard_pattern.aggregate.from(iterator)
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
local ignore = wildcard_pattern.aggregate.from([[
# This is a test ignore file
*.md
/from-root-only
exact-name
]])

local function should_match(path)
    assert.are.same(path, wildcard_pattern.any_match(ignore, path))
end
local function should_not_match(path)
    assert.is_falsy(wildcard_pattern.any_match(ignore, path))
end

describe("Patterns from ignore files", function()
    it("when called directly or with `:any_match` calls wildcard_pattern.any_match", function()
        assert.are.same(wildcard_pattern.any_match(ignore, "README.md"), ignore("README.md"))
        assert.are.same(wildcard_pattern.any_match(ignore, "README.md"), ignore:any_match("README.md"))
        assert.are.same(wildcard_pattern.any_match(ignore, "tutorial/1-Getting-started.md"), ignore("tutorial/1-Getting-started.md"))
        assert.are.same(wildcard_pattern.any_match(ignore, "tutorial/1-Getting-started.md"), ignore:any_match("tutorial/1-Getting-started.md"))
    end)

    it("match exact patterns after '/' boundaries", function()
        should_match("exact-name")
        should_match("dir/exact-name")
        should_not_match("dir/not-exact-name")
    end)

    it("match in any directory depth if '/' is not found in it", function()
        should_match("README.md")
        should_match("tutorial/1-Getting-started.md")
    end)

    it("match only from current directory with a leading '/'", function()
        should_match("from-root-only")
        should_not_match("tutorial/from-root-only")
    end)
end)
