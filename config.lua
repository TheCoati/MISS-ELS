ELSConfig = {}

ELSConfig.AudioBanks = {
    'DLC_WMSIRENS\\SIRENPACK_ONE',
}

ELSConfig.LightRange = 20.0
ELSConfig.LightIntensity = 0.1
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

-- TODO

-- Whether vehicle passengers are allowed to control the lights and sirens
Config.AllowPassengers = false

-- Whether you can toggle the siren, even when the lights are out
Config.SirenAlwaysAllowed = false

-- Whether vehicle indicator control should be enabled
-- The indicators are controlled with arrow left, right and down on your keyboard
Config.Indicators = true

-- Enables a short honk when a siren is activated
Config.HornBlip = true

-- Enables a short beep when a light stage or siren is activated
Config.Beeps = false

-- Enables controller support for controlling the primary light stage and the sirens
-- DPAD_LEFT = toggle primary lights
-- DPAD_DOWN = toggle siren 1
-- B = activate next siren
Config.ControllerSupport = true

-- Sets keybinds for various actions
-- See https://docs.fivem.net/docs/game-references/controls for a list of codes
Config.KeyBinds = {
    PrimaryLights = 85, -- Q
    SecondaryLights = 311, -- K
    MiscLights = 182, -- L
    ActivateSiren = 19, -- LEFT ALT
    NextSiren = 45, -- R
    Siren1 = 157, -- 1
    Siren2 = 158, -- 2
    Siren3 = 160, -- 3
    Siren4 = 164, -- 4
    IndicatorLeft = 174, -- ARROW LEFT
    IndicatorRight = 175, -- ARROW RIGHT
    IndicatorHazard = 173, -- ARROW DOWN
    ExtrasMenu = 303, -- U
}
