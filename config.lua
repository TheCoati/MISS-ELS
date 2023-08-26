ELSConfig = {}
ELSConfig.Debug = true

-- Custom audio banks to load on startup
-- For example when using WMServerSirens (https://github.com/Walsheyy/WMServerSirens)
ELSConfig.AudioBanks = {
    'DLC_WMSIRENS\\SIRENPACK_ONE',
}

-- When disabled AI vehicles will ignore the sirens and emergency lights
-- This will also the blinking of the rear lights with emergency lights on
ELSConfig.EnableNativeSires = true

-- Light related configuration
ELSConfig.LightRange = 20.0
ELSConfig.LightIntensity = 0.15
ELSConfig.LightColors = {
    blue  = { 0, 0, 255 },
    red   = { 255, 0, 0 },
    green = { 0, 255, 0 },
    white = { 255, 255, 255 },
    amber = { 255, 194, 0 },
}

ELSConfig.DefaultKeys = {
    horn = 'E',
    modiforce = 'LMENU'
}
