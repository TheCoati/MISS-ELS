-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃              Commands                ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- Press horn
RegisterCommand('+elsHorn', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local netVehicle = VehToNet(vehicle)

    TriggerServerEvent('els:server:horn', netVehicle, true)
end)

-- Release horn
RegisterCommand('-elsHorn', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local netVehicle = VehToNet(vehicle)

    TriggerServerEvent('els:server:horn', netVehicle, false)
end)

-- Press toggle modiforce
RegisterCommand('+elsToggleModiforce', function()
    ELS.Functions.ShowModiforce()
end)

-- Release toggle modiforce
RegisterCommand('-elsToggleModiforce', function()
    ELS.Functions.HideModiforce()
end)

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃             Keybindings              ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

RegisterKeyMapping('+elsHorn', 'Sound vehicle horn', 'keyboard', ELSConfig.DefaultKeys['horn'])
RegisterKeyMapping('+elsToggleModiforce', 'Toggle Modiforce interface', 'keyboard', ELSConfig.DefaultKeys['modiforce'])