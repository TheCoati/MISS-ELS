fx_version 'cerulean'
game 'gta5'

author 'TheCoati <hello@thecoati.dev>'
description 'Server-Sided Emergency Lighting System for FiveM.'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'lib/SLAXML.lua',
    'server/parseVCF.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/sounds/**/*.ogg'
}

ui_page 'html/index.html'

dependencies {
    'baseevents',
}
