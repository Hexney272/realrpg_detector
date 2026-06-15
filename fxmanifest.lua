fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'realrpg_detector'
author 'ChatGPT - custom RealRPG style script'
description 'Több zónás fémdetektor / detektorozás rendszer ESX Legacy + ox_inventory szerverhez'
version '1.1.0'

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
    'html/style.css',
    'html/app.js'
}

dependency 'es_extended'
