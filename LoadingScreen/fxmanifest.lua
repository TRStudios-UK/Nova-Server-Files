fx_version 'cerulean'
games { 'gta5' }

author 'Redven Biker (XLife.fr)'
description 'Discord : https://discord.gg/YxCcxY6bYF'
version '1.0.0'

loadscreen 'index.html'
loadscreen_manual_shutdown 'yes'
client_script 'client.lua'

files {
    'index.html',
    'css/style.css',
    'music/music.mp3'
}

client_script "@Badger-Anticheat-master/acloader.lua"