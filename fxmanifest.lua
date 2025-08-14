fx_version 'cerulean'
game 'gta5'

author 'PulseScripts'
description 'Fraud Script'
version '1.1.3'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/shop.lua'
}

server_scripts {
    'server/bridge/*',
    'server/main.lua',
    'server/shop.lua'
}

files {
	'locales/*.json'
}

dependencies {
    'ox_lib'
}

lua54 'yes'
