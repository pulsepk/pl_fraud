fx_version 'cerulean'
game 'gta5'

author 'PulseScripts'
description 'Fraud Script'
version '1.1.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/bridge/*',
    'server/main.lua'
}

files {
	'locales/*.json'
}

dependencies {
    'ox_lib'
}

lua54 'yes'
