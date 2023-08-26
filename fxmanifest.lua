fx_version 'cerulean'
game 'gta5'

author 'TheCoati <hello@thecoati.dev>'
description 'Server-Sided Emergency Lighting System for FiveM.'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/commands.lua',
    'client/events.lua',
}

server_scripts {
    'server/lib/SLAXML.lua',  -- SLAXML (https://github.com/Phrogz/SLAXML)
    'server/lib/MISSELS.lua', -- MISS-ELS VCF Parser (https://github.com/matsn0w/MISS-ELS/blob/main/resource/server/parseVCF.lua)
    'server/main.lua',
}

files {
    'html/index.html',
    'html/assets/js/**/*.js',
    'html/assets/css/**/*.css',
    'html/assets/sounds/**/*.ogg',
}

ui_page 'html/index.html'
