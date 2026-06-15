fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'realrpg_detector'
author 'RealRPG'
description 'Több zónás fémdetektor rendszer React NUI-val - ESX Legacy + ox_inventory'
version '2.0.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

files {
    'html/index.html',
    'html/assets/*.js',
    'html/assets/*.css'
}

dependency 'es_extended'
