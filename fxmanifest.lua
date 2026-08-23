fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kaja Hasir'
description 'Human Labs Raid'
version '1.3.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua', -- Remove if not using [ox]
	'config.lua',
	'locale.lua',
	'exports/**'
}

client_scripts {
	'client/**'
}

server_scripts {
	'server/**'
}

files {
	'html/**',
}
