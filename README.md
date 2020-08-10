# wildcard\_pattern.lua
[![Build Status](https://travis-ci.org/gilzoide/wildcard_pattern.lua.svg?branch=master)](https://travis-ci.org/gilzoide/wildcard_pattern.lua)

Lua library for using shell-like wildcards as string patterns with support for importing gitignore-like file content.



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

