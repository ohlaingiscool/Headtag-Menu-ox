fx_version 'cerulean'
game 'gta5'
author 'JaredScar & JoeV2'
description 'Badger\'s DiscordTagIDs with A Headtag Menu & A HUD'
version '1.2.3'
lua54 'yes'

client_scripts {
    'dependencies/NativeUI.lua', 
    'config.lua',
    'client.lua',
    'hud.lua'
}
server_scripts {
    "config.lua",
    "server.lua"
}

server_exports {
    "HideUserTag",
    "ShowUserTag"
}

