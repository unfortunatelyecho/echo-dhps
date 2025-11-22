fx_version 'cerulean'
game 'gta5'

author 'Echo'
description 'Dynamic Heist Planning System - Multi-Framework (QBCore/QBX/ESX)'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'bridge/framework.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'locales/*.json'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

lua54 'yes'