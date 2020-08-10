local wildcard_pattern = require 'wildcard_pattern'

local patterns = {
    wildcard_pattern.from_wildcard("*.lua"),
    wildcard_pattern.from_wildcard("spec/*.lua"),
}

local function should_match(path)
    assert.is_truthy(wildcard_pattern.any_match(patterns, path))
end
local function should_not_match(path)
    assert.is_falsy(wildcard_pattern.any_match(patterns, path))
end

describe("Calling `any_match` with a table of patterns", function()
    it("returns truthy if any pattern matches", function()
        should_match("wildcard_pattern.lua")
        should_match("spec/wildcard_pattern_spec.lua")
        should_match("spec/wildcard_pattern_any_match_spec.lua")
    end)

    it("returns falsy if none of the patterns match", function()
        should_not_match("examples/simple_wildcards.lua")
        should_not_match("UNLICENSE")
        should_not_match("README.md")
        should_not_match(".gitignore")
        should_not_match(".travis.yml")
    end)
end)

