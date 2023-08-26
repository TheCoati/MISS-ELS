-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃              CitizenFX               ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

-- Triggers when resource gets started
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    ELS.Functions.InitResource()
end)

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃               Client                 ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

RegisterNetEvent('els:client:init')
AddEventHandler('els:client:init', function(data)
    ELS.Functions.Log('debug', 'Received event "els:client:init" with ' .. #data .. ' vehicles')

    ELS.ELSData = data
end)

RegisterNetEvent('els:client:registerVehicle')
AddEventHandler('els:client:registerVehicle', function(netVehicle)
    ELS.Functions.Log('debug', 'Received event "els:client:registerVehicle" for vehicle ' .. netVehicle)

    ELS.Functions.RegisterVehicle(netVehicle)
end)

RegisterNetEvent('els:client:deregisterVehicle')
AddEventHandler('els:client:deregisterVehicle', function(netVehicle)
    ELS.Functions.Log('debug', 'Received event "els:client:deregisterVehicle" for vehicle ' .. netVehicle)

    ELS.Functions.UnregisterVehicle(netVehicle)
end)

RegisterNetEvent('els:client:updateState')
AddEventHandler('els:client:updateState', function(netVehicle, state)
    ELS.Functions.Log('debug', 'Received event "els:client:updateState" for vehicle ' .. netVehicle)

    ELS.Functions.UpdateVehicleState(netVehicle, state)
end)

-- ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
-- ┃                 NUI                  ┃
-- ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

RegisterNUICallback('toggle', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local netVehicle = VehToNet(vehicle)

    local event = data.event

    if event == 'toggleSiren' then
        TriggerServerEvent('els:server:toggleSiren', netVehicle)
    end

    if event == 'toggleLightPrimary' then
        TriggerServerEvent('els:server:toggleLightPrimary', netVehicle)
    end

    if event == 'toggleLightWarning' then
        TriggerServerEvent('els:server:toggleLightWarning', netVehicle)
    end

    if event == 'toggleLightSecondary' then
        TriggerServerEvent('els:server:toggleLightSecondary', netVehicle)
    end
end)
