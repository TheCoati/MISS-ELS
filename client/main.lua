local vcfData
local vcfVehicles = {}
local nuiOpen = false

function GetELSVehicleName(model)
    for k, v in pairs(vcfData) do
        if model == GetHashKey(k) and v.extras ~= nil then
            return k
        end
    end

    return false
end

function IsELSVehicle(model)
    return GetELSVehicleName(model) ~= false
end

local function CreateEnviromentLight(vehicle, extra, offset, color)
    local boneIndex = GetEntityBoneIndexByName(vehicle, 'extra_' .. extra)
    local coords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local position = coords + offset

    local rgb = { 0, 0, 0 }
    local range = Config.EnvironmentalLights.Range or 50.0
    local intensity = Config.EnvironmentalLights.Intensity or 1.0
    local shadow = 1.0

    if string.lower(color) == 'blue' then rgb = { 0, 0, 255 }
    elseif string.lower(color) == 'red' then rgb = { 255, 0, 0 }
    elseif string.lower(color) == 'green' then rgb = { 0, 255, 0 }
    elseif string.lower(color) == 'white' then rgb = { 255, 255, 255 }
    elseif string.lower(color) == 'amber' then rgb = { 255, 194, 0}
    end

    DrawLightWithRangeAndShadow(position.x, position.y, position.z, rgb[1], rgb[2], rgb[3], range, intensity, shadow)
end

function UpdateSiren(vehicleId, status)
    local vcfVehicle = vcfVehicles[vehicleId]
    local data = vcfData[vcfVehicle.modelName]

    if vcfVehicle.soundId then
        StopSound(vcfVehicle.soundId)
        ReleaseSoundId(vcfVehicle.soundId)
    end

    if status >= 1 and status <= 4 then
        vcfVehicle.soundId = GetSoundId()

        PlaySoundFromEntity(vcfVehicle.soundId, data.sounds['srnTone' .. status].audioString, vcfVehicle.vehicle, data.sounds['srnTone' .. status].soundSet, 0, 0)
    end

    vcfVehicle.state.siren = status

    SetVehicleHasMutedSirens(vcfVehicle.vehicle, true)
end

function UpdateLight(vehicleId, stage, toggle)
    local vcfVehicle = vcfVehicles[vehicleId]
    local data = vcfData[vcfVehicle.modelName]

    if not toggle then
        vcfVehicle.state[stage] = toggle
        SetVehicleSiren(vcfVehicle.vehicle, false)
        return
    end

    local pattern = stage

    if stage == 'secondary' then
        pattern = 'rearreds'
    end

    if stage == 'warning' then
        pattern = 'secondary'
    end

    Citizen.CreateThread(function()
        Wait(1)
        SetVehicleSiren(vcfVehicle.vehicle, data.patterns[pattern].isEmergency)
    end)

    vcfVehicle.state[stage] = toggle

    CreateThread(function()
        while vcfVehicle.state[stage] do
            SetVehicleEngineOn(vcfVehicle.vehicle, true, true, false)

            local lastFlash = {}

            for _, flash in ipairs(data.patterns[pattern]) do
                if vcfVehicle.state[stage] then
                    for _, extra in ipairs(flash['extras']) do
                        SetVehicleExtra(vcfVehicle.vehicle, extra, 0)

                        table.insert(lastFlash, extra)
                    end

                    Citizen.Wait(flash.duration)
                end

                for _, v in ipairs(lastFlash) do
                    SetVehicleExtra(vcfVehicle.vehicle, v, 1)
                end

                lastFlash = {}
            end

            Citizen.Wait(1)
        end
    end)
end

function ResetVehicleExtras(vehicleId)
    local vcfVehicle = vcfVehicles[vehicleId]
    local data = vcfData[vcfVehicle.modelName]

    for extra, info in pairs(data.extras) do
        if info.enabled == true then
            SetVehicleExtra(vcfVehicle.vehicle, extra, true)
        end
    end
end

RegisterNetEvent('els:client:registerVehicle')
AddEventHandler('els:client:registerVehicle', function(vehicleId)
    vcfVehicles[vehicleId] = {
        initialized = false,
        soundId = nil, -- Fresh Sound ID
        state = {},
    }
end)

RegisterNetEvent('els:client:deregisterVehicle')
AddEventHandler('els:client:deregisterVehicle', function(vehicleId)
    local vcfVehicle = vcfVehicles[vehicleId]

    StopSound(vcfVehicle.soundId)
    ReleaseSoundId(vcfVehicle.soundId)

    vcfVehicles[vehicleId] = nil
end)

RegisterNetEvent('els:client:updateState')
AddEventHandler('els:client:updateState', function(vehicleId, state)
    local exists = NetworkDoesEntityExistWithNetworkId(vehicleId)

    if not exists then
        return
    end

    local vcfVehicle = vcfVehicles[vehicleId]

    if state.siren ~= vcfVehicle.state.sire then
        UpdateSiren(vehicleId, state.siren)
    end

    if state.primary ~= vcfVehicle.state.primary then
        UpdateLight(vehicleId, 'primary', state.primary)
    end

    if state.secondary ~= vcfVehicle.state.secondary then
        UpdateLight(vehicleId, 'secondary', state.secondary)
    end

    if state.warning ~= vcfVehicle.state.warning then
        UpdateLight(vehicleId, 'warning', state.warning)
    end
end)

RegisterNetEvent('els:client:init')
AddEventHandler('els:client:init', function(data)
    vcfData = data
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for _, v in ipairs(Config.AudioBanks) do
        RequestScriptAudioBank(v, false)
    end

    while vcfData == nil do
        TriggerServerEvent('els:server:init')
        Wait(500)
    end

    CreateThread(function()
        while true do
            for vehicleId, vehicleData in pairs(vcfVehicles) do
                local exists = NetworkDoesEntityExistWithNetworkId(vehicleId)

                if not exists and vehicleData.initialized then
                    vehicleData.initialized = false

                    StopSound(vehicleData.soundId)

                    goto continue
                end

                if exists and not vehicleData.initialized then
                    local vehicle = NetToVeh(vehicleId)
                    local model = GetEntityModel(vehicle)
                    local modelName = GetELSVehicleName(model)

                    vehicleData.initialized = true
                    vehicleData.vehicle = vehicle
                    vehicleData.model = model
                    vehicleData.modelName = modelName

                    SetVehRadioStation(vehicle, 'OFF')
                    SetVehicleRadioEnabled(vehicle, false)
                    SetVehicleAutoRepairDisabled(vehicle, true)
                    SetVehicleHasMutedSirens(vehicle, true)
                    ResetVehicleExtras(vehicleId)

                    TriggerServerEvent('els:server:requestState', vehicleId)
                end

                ::continue::
            end

            Wait(50)
        end
    end)

    CreateThread(function()
        local isInVehicle = false

        while true do
            local playerId = PlayerId()
            local playerPed = PlayerPedId()

            if not isInVehicle and not IsPlayerDead(playerId) and IsPedInAnyVehicle(playerPed, false) then
                isInVehicle = true

                local vehicle = GetVehiclePedIsUsing(playerPed)
                local model = GetEntityModel(vehicle)

                if not IsELSVehicle(model) then
                    goto continue
                end

                TriggerServerEvent('els:server:enteredVehicle', vehicle, model, VehToNet(vehicle))

                goto continue
            end

            if isInVehicle and not IsPlayerDead(playerId) and not IsPedInAnyVehicle(playerPed, false) then
                isInVehicle = false
            end

            ::continue::
            Wait(50)
        end
    end)

    CreateThread(function()
        while true do
            DisableControlAction(0, 86, true)

            for vehicleId, vehicleData in pairs(vcfVehicles) do
                local data = vcfData[vehicleData.modelName]

                if data then
                    for extra, info in pairs(data.extras) do
                        if IsVehicleExtraTurnedOn(vehicleData.vehicle, extra) and info.env_light then
                            local offset = vector3(info.env_pos.x, info.env_pos.y, info.env_pos.z)

                            CreateEnviromentLight(vehicleData.vehicle, extra, offset, info.env_color)
                        end
                    end
                end
            end

            Citizen.Wait(1)
        end
    end)
end)

RegisterCommand('+horn', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local netVehicle = VehToNet(vehicle)

    TriggerServerEvent('els:server:horn', netVehicle, true)
end)

RegisterCommand('-horn', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local netVehicle = VehToNet(vehicle)

    TriggerServerEvent('els:server:horn', netVehicle, false)
end)

RegisterCommand('+toggleHonac', function()
    SendNUIMessage({ event = 'show' })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    nuiOpen = true

    CreateThread(function()
        while nuiOpen do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 3, true)
            DisableControlAction(0, 4, true)
            DisableControlAction(0, 5, true)
            DisableControlAction(0, 6, true)

            Wait(1)
        end
    end)
end)

RegisterCommand('-toggleHonac', function()
    nuiOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ event = 'hide' })
end)

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

RegisterKeyMapping('+toggleHonac', 'Toggle Honac interface', 'keyboard', 'LMENU')
RegisterKeyMapping('+horn', 'Toggle sped up siren', 'keyboard', 'E')
