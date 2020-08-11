local wildcard_pattern = require 'wildcard_pattern'

local function import_file(path)
    local file = assert(io.open(path))
    local result = wildcard_pattern.from_ignore(file)
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
    local from_text = import_text('.gitignore')
    local from_iterator = import_iterator('.gitignore')

    assert.are.same(from_file, from_text)
    assert.are.same(from_file, from_iterator)
    assert.are.same(from_text, from_iterator)
end)
