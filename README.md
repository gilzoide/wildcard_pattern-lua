# wildcard\_pattern.lua
[![Build Status](https://travis-ci.org/gilzoide/wildcard_pattern.lua.svg?branch=master)](https://travis-ci.org/gilzoide/wildcard_pattern.lua)

Lua library for using shell-like wildcards as string patterns with support for importing gitignore-like file content.


## Installation
Copy `wildcard_pattern.lua` to your LUA\_PATH or install with [LuaRocks](https://luarocks.org/):

    $ luarocks install wildcard_pattern


## Usage

```lua
local wildcard_pattern = require 'wildcard_pattern'

-- Create simple lua string patterns from wildcard ones
local patt = wildcard_pattern.from_wildcard("*.lua")
assert(string.match("hello_world.lua", patt))

-- Or import a gitignore-like content from file
local ignore_patterns = wildcard_pattern.aggregate.from(io.open(".gitignore"))
-- local ignore_patterns = wildcard_pattern.aggregate.from(io.open(".gitignore"):read('*a'))  -- or from text
-- local ignore_patterns = wildcard_pattern.aggregate.from(io.lines(".gitignore"))  -- or from an iterator function
assert(not wildcard_pattern.any_match(ignore_patterns, "hello_world.lua"))  -- assuming your .gitignore have no rules for ignoring hello_world.lua
-- `any_match` is also a method and __call metamethod for ignore files
assert(not ignore_patterns:any_match("hello_world.lua"))
assert(not ignore_patterns("hello_world.lua"))

-- You can extend your aggregate wildcard with `insert`, `extend` or `extend_from` methods
ignore_patterns:insert("hello_world.lua")
ignore_patterns:extend("hello_world.lua", "hello_world[0-9].lua")
ignore_patterns:extend_from([[
# `extend_from` uses gitignore-like file content, just like `wildcard_pattern.aggregate.from`
world_hello?.lua
**.ignore
]])
```


## What is supported
- A single asterisk `*` matches zero or more characters that are not directory separators `/`
- Two consecutive asterisks `**` match zero or more characters
- A question mark `?` match any character that is not a directory separator `/`
- Brackets `[...]` denote character sets and ranges, like `[abcd]` and `[a-d]`
- Brackets may be negated with an exclamation mark `[!...]`
- Backslash `\` escapes are maintained


## What is not supported
- Prefix exclamation mark `!` for negating the pattern in ignore files


## Running tests
Run tests using [busted](https://olivinelabs.com/busted/)

    $ busted

