-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃              Commands                ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- Press horn
RegisterCommand('+elsHorn', function()
    local elsVehicle = ELS.Functions.GetCurrentELSVehicle()

    if elsVehicle == false then
        return
    end

    TriggerServerEvent('els:server:horn', elsVehicle.netVehicle, true)
end)

-- Release horn
RegisterCommand('-elsHorn', function()
    local elsVehicle = ELS.Functions.GetCurrentELSVehicle()

    if elsVehicle == false then
        return
    end

    TriggerServerEvent('els:server:horn', elsVehicle.netVehicle, false)
end)

-- Press toggle modiforce
RegisterCommand('+elsToggleModiforce', function()
    if not ELS.Functions.IsInELSVehicle() then
        return
    end

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