package = 'wildcard_pattern'
version = 'scm-2'
source = {
	url = 'git://github.com/gilzoide/wildcard_pattern.lua',
}
description = {
	summary = 'Library for using shell-like wildcards as string patterns',
	detailed = [[
Lua library for using shell-like wildcards as string patterns.
It has support for importing gitignore-like file content, aggregated in a callable object so you can easily try matching any of the patterns imported.
]],
	license = 'Unlicense',
	maintainer = 'gilzoide <gilzoide@gmail.com>'
}
dependencies = {
	'lua >= 5.1',
}
build = {
	type = 'builtin',
	modules = {
		wildcard_pattern = 'wildcard_pattern.lua'
	}
}
