ELS.Functions = {}

--- Initialize the resource
function ELS.Functions.InitResource()
    -- Load audio banks from configuration
    for _, v in ipairs(ELSConfig.AudioBanks) do
        RequestScriptAudioBank(v, false)
    end

    -- Request VCF data from the server to cache at the client
    while ELS.ELSData == nil do
        TriggerServerEvent('els:server:init')
        Wait(500) -- Wait till loaded
    end

    -- Vehicle enter and exit checking loop
    -- Detects when player enters a vehicle
    Citizen.CreateThread(function()
        local isInVehicle = false

        while true do
            local playerId = PlayerId()
            local playerPed = PlayerPedId()
            local isDead = IsPlayerDead(playerId)
            local pedIsInVehicle = IsPedInAnyVehicle(playerPed, false)

            -- Player has entered a vehicle
            if not isInVehicle and not isDead and pedIsInVehicle then
                isInVehicle = true -- Update cached value

                local vehicle = GetVehiclePedIsUsing(playerPed)
                local model = GetEntityModel(vehicle)

                if not ELS.Functions.IsELSVehicle(model) then
                    goto continue
                end

                local netVehicle = VehToNet(vehicle)

                TriggerServerEvent('els:server:enteredVehicle', vehicle, model, netVehicle)

                ELS.Functions.Log('debug', 'Ped entered ELS vehicle')
                goto continue -- Continue to next loop
            end

            -- Player has left a vehicle
            if isInVehicle and not isDead and not pedIsInVehicle then
                isInVehicle = false
            end

            ::continue::
            Citizen.Wait(50)
        end
    end)

    -- OneSync render checking loop
    -- Checks if vehicle is within render on the client
    Citizen.CreateThread(function()
        while true do
            for netVehicle, elsVehicle in pairs(ELS.ELSVehicles) do
                local exists = NetworkDoesEntityExistWithNetworkId(netVehicle)

                -- Vehicle got out of scope of the client
                if not exists and elsVehicle.initialized then
                    ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' has become unavailable')
                    ELS.Functions.UnloadVehicle(netVehicle)
                    goto continue
                end

                -- Vehicle got within scope of the client
                if exists and not elsVehicle.initialized then
                    ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' has become available')
                    ELS.Functions.LoadVehicle(netVehicle)
                end

                ::continue::
            end

            Citizen.Wait(50)
        end
    end)

    Citizen.CreateThread(function()
        while true do
            if ELS.Functions.IsInELSVehicle() then
                -- Disable default horn usage
                DisableControlAction(0, 86, true)
            end

            for _, vehicleData in pairs(ELS.ELSVehicles) do
                -- Skip vehicles that are not available to the client
                if not vehicleData.initialized then
                    goto continue
                end

                local data = ELS.ELSData[vehicleData.modelName]

                if data then
                    for extra, info in pairs(data.extras) do
                        local vehicle = vehicleData.vehicle
                        local isExtraOn = IsVehicleExtraTurnedOn(vehicle, extra)

                        if isExtraOn and info.env_light then
                            local offset = vector3(info.env_pos.x, info.env_pos.y, info.env_pos.z)
                            local color = info.env_color

                            -- Draw light this frame
                            ELS.Functions.DrawEnviromentLightThisFrame(vehicle, extra, offset, color)
                        end
                    end
                end

                ::continue::
            end

            Citizen.Wait(1)
        end
    end)

    ELS.Functions.Log('info', 'MIX-ELS has been initialized')
    ELS.Initialized = true
end

--- Register an ELS vehicle to the client register for checking
--- @param netVehicle number The network ID of the vehicle
function ELS.Functions.RegisterVehicle(netVehicle)
    -- Check if vehicle does not already exists
    if ELS.ELSVehicles[netVehicle] then
        ELS.Functions.Log('warn', 'Tried to load ELS vehicle twice')
        return
    end

    ELS.ELSVehicles[netVehicle] = {
        initialized = false, -- Boolean if the vehicles has been initialized on the client when available
        soundId = nil, -- Sound ID (https://docs.fivem.net/natives/?_0x430386FE9BF80B45)
        state = {}, -- State of vehicle lights and sirens
    }

    ELS.Functions.Log('debug', 'Vehicle ' .. netVehicle .. ' has been registered as ELS vehicle')
end

--- Remove an ELS vehicle from client register to stop checking
--- @param netVehicle number The network ID of the vehicle
function ELS.Functions.UnregisterVehicle(netVehicle)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    -- Check if vehicle is registered
    if not elsVehicle then
        ELS.Functions.Log('warn', 'Tried to unload a non registered vehicle from the ELS')
        return
    end

    -- Unload the vehicle when available to the client
    ELS.Functions.UnloadVehicle(netVehicle)

    -- Remove vehicle
    ELS.ELSVehicles[netVehicle] = nil

    ELS.Functions.Log('debug', 'Vehicle ' .. netVehicle .. ' has been unregistered as ELS vehicle')
end

--- Load the vehicle when the vehicle becomes available to the client
--- @param netVehicle number The network ID of the vehicle
function ELS.Functions.LoadVehicle(netVehicle)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    elsVehicle.initialized = true

    local vehicle = NetToVeh(netVehicle)
    local model = GetEntityModel(vehicle)
    local modelName = ELS.Functions.GetELSVehicleModelName(model)

    -- Set cached data
    elsVehicle.vehicle = vehicle
    elsVehicle.netVehicle = netVehicle
    elsVehicle.model = model
    elsVehicle.modelName = modelName

    -- Set vehicle defaults
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleRadioEnabled(vehicle, false)
    SetVehicleAutoRepairDisabled(vehicle, true)
    SetVehicleHasMutedSirens(vehicle, true)

    -- Reset all extras on the vehicle
    ELS.Functions.ResetVehicleExtras(netVehicle)

    -- Request the state of the vehicle
    TriggerServerEvent('els:server:requestState', netVehicle)

    ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' has been loaded')
end

--- Unload the vehicle when the vehicle becomes unavailable to the client
--- @param netVehicle number The network ID of the vehicle
function ELS.Functions.UnloadVehicle(netVehicle)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    if not elsVehicle.initialized then
        return
    end

    elsVehicle.initialized = false

    -- Unload cached values to preserve memory
    elsVehicle.vehicle = nil
    elsVehicle.netVehicle = nil
    elsVehicle.model = nil
    elsVehicle.modelName = nil

    -- Stop all playing sounds by vehicle
    StopSound(elsVehicle.soundId)
    ReleaseSoundId(elsVehicle.soundId)

    ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' has been unloaded')
end

--- Reset all extras on a ELS vehicle
--- Can only be done when vehicle is within render of the client
--- @param netVehicle number The network ID of the vehicle
function ELS.Functions.ResetVehicleExtras(netVehicle)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    if not elsVehicle.initialized then
        return
    end

    local elsData = ELS.ELSData[elsVehicle.modelName]

    for extra, state in pairs(elsData.extras) do
        if state.enabled == true then
            SetVehicleExtra(elsVehicle.vehicle, extra, true)
        end
    end

    ELS.Functions.Log('debug', 'Extra\'s of ELS vehicle ' .. netVehicle .. ' has been reset')
end

--- Set the siren tone of the vehicle
--- @param netVehicle number The network ID of the vehicle
--- @param status number The status of the siren to activate
function ELS.Functions.SetVehicleSiren(netVehicle, status)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    if not elsVehicle.initialized then
        return
    end

    -- Release and stop current
    if elsVehicle.soundId then
        StopSound(elsVehicle.soundId)
        ReleaseSoundId(elsVehicle.soundId)
    end

    if status >= 1 and status <= 4 then
        local elsData = ELS.ELSData[elsVehicle.modelName]

        -- Set new sound ID
        elsVehicle.soundId = GetSoundId()

        local audioName = elsData.sounds['srnTone' .. status].audioString
        local audioRef = elsData.sounds['srnTone' .. status].soundSet or ''

        PlaySoundFromEntity(elsVehicle.soundId, audioName, elsVehicle.vehicle, audioRef, 0, 0)
        SetVariableOnSound(elsVehicle.soundId, "Loudness", 0.1)
    end

    elsVehicle.state.siren = status

    SetVehicleHasMutedSirens(elsVehicle.vehicle, true)

    ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' sirens set to state ' .. status)
end

--- Toggle the light stage of a vehicle
--- @param netVehicle number The network ID of the vehicle
--- @param stage string The stage to toggle
--- @param toggle boolean The toggle value of the stage
function ELS.Functions.SetVehicleLights(netVehicle, stage, toggle)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    if not elsVehicle.initialized then
        return
    end

    if not toggle then
        elsVehicle.state[stage] = toggle

        -- Disable native siren
        SetVehicleSiren(elsVehicle.vehicle, false)

        ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' light state ' .. stage .. ' set to ' .. tostring(toggle))
        return
    end

    local pattern = stage
    local elsData = ELS.ELSData[elsVehicle.modelName]

    if stage == 'secondary' then
        pattern = 'rearreds'
    end

    if stage == 'warning' then
        pattern = 'secondary'
    end

    elsVehicle.state[stage] = toggle

    -- Set vehicle siren loop in new thread
    Citizen.CreateThread(function()
        -- Set native sirens when the given lights are emergency lights
        SetVehicleSiren(elsVehicle.vehicle, elsData.patterns[pattern].isEmergency)

        -- As long the sirens are toggled
        while elsVehicle.state[stage] do
            -- Keep the engine on as long the lights are on
            SetVehicleEngineOn(elsVehicle.vehicle, true, true, false)

            local flashed = {}

            for _, flash in ipairs(elsData.patterns[pattern]) do
                if elsVehicle.state[stage] then
                    for _, extra in ipairs(flash['extras']) do
                        SetVehicleExtra(elsVehicle.vehicle, extra, 0)

                        table.insert(flashed, extra)
                    end

                    Citizen.Wait(flash.duration)
                end

                -- Disable the flashed lights
                for _, v in ipairs(flashed) do
                    SetVehicleExtra(elsVehicle.vehicle, v, 1)
                end

                flashed = {} -- Reset flashed lights
            end

            Citizen.Wait(1)
        end
    end)

    ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' light state ' .. stage .. ' set to ' .. tostring(toggle))
end

--- Draw environment light from an extra on a vehicle to visualize the lights
--- @param vehicle number The client vehicle id to draw light from
--- @param extra number The extra index to draw the light from
--- @param offset any The extra offset added to the extra to draw the light
--- @param color string The color name to draw
function ELS.Functions.DrawEnviromentLightThisFrame(vehicle, extra, offset, color)
    local boneIndex = GetEntityBoneIndexByName(vehicle, 'extra_' .. extra)
    local coords = GetWorldPositionOfEntityBone(vehicle, boneIndex)
    local position = coords + offset

    local range = ELSConfig.LightRange or 50.0
    local intensity = ELSConfig.LightIntensity or 1.0
    local rgb = ELSConfig.LightColors[string.lower(color)] or { 255, 255, 255 }
    local shadow = 1.0

    DrawLightWithRangeAndShadow(position.x, position.y, position.z, rgb[1], rgb[2], rgb[3], range, intensity, shadow)
end

--- Update the overall state of the network vehicle
--- @param netVehicle number The network ID of the vehicle
--- @param state table The fully updated state of the vehicle
function ELS.Functions.UpdateVehicleState(netVehicle, state)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    if not elsVehicle.initialized then
        return
    end

    -- Update siren when state changed
    if state.siren ~= elsVehicle.state.siren then
        ELS.Functions.SetVehicleSiren(netVehicle, state.siren)
    end

    -- Update primary when primary changed
    if state.primary ~= elsVehicle.state.primary then
        ELS.Functions.SetVehicleLights(netVehicle, 'primary', state.primary)
    end

    -- Update secondary when secondary changed
    if state.secondary ~= elsVehicle.state.secondary then
        ELS.Functions.SetVehicleLights(netVehicle, 'secondary', state.secondary)
    end

    -- Update warning lights when warning lights changed
    if state.warning ~= elsVehicle.state.warning then
        ELS.Functions.SetVehicleLights(netVehicle, 'warning', state.warning)
    end

    ELS.Functions.Log('debug', 'ELS vehicle ' .. netVehicle .. ' state has been updated')
end

--- Get the vehicle model name of an model hash
--- Only works when providing a hash that is known to be an ELS vehicle
--- @param model string joaat hash to match with model name
function ELS.Functions.GetELSVehicleModelName(model)
    for k, v in pairs(ELS.ELSData) do
        if model == GetHashKey(k) and v.extras ~= nil then
            return k
        end
    end

    return false
end

--- Check if an model hash is an ELS vehicle
--- @param model string joaat hash to match with model name
function ELS.Functions.IsELSVehicle(model)
    return ELS.Functions.GetELSVehicleModelName(model) ~= false
end

function ELS.Functions.GetCurrentELSVehicle()
    local playerPed = PlayerPedId()
    local isPedInVehicle = IsPedInAnyVehicle(playerPed, false)

    if not isPedInVehicle then
        return false
    end

    local vehicle = GetVehiclePedIsUsing(playerPed)
    local netVehicle = VehToNet(vehicle)
    local elsVehicle = ELS.ELSVehicles[netVehicle]

    return elsVehicle or false
end

function ELS.Functions.IsInELSVehicle()
    return ELS.Functions.GetCurrentELSVehicle() ~= false
end

--- Show the modiforce NUI interface
function ELS.Functions.ShowModiforce()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ event = 'show' })

    ELS.ShowModiforce = true

    CreateThread(function()
        while ELS.ShowModiforce do
            -- Disable mouse camera rotation
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 3, true)
            DisableControlAction(0, 4, true)
            DisableControlAction(0, 5, true)
            DisableControlAction(0, 6, true)

            Wait(1)
        end
    end)
end

--- Hide the modiforce NUI interface
function ELS.Functions.HideModiforce()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ event = 'hide' })

    ELS.ShowModiforce = false
end

--- Log a message to the console
--- @param severity string The severity of the log message
--- @param message string Message to log
function ELS.Functions.Log(severity, message)
    if string.lower(severity) == 'info' then
        print('[INFO] ' .. message)
        return
    end

    if string.lower(severity) == 'warn' then
        print('[WARN] ' .. message)
        return
    end

    if string.lower(severity) == 'error' then
        print('[ERROR] ' .. message)
        return
    end

    if string.lower(severity) == 'debug' and ELSConfig.Debug then
        print('[DEBUG] ' .. message)
        return
    end

    print(message)
end
