local vcfData = {}

local function parseObjSet(data, fileName)
    local xml = SLAXML:dom(data)

    if xml and xml.root and xml.root.name == 'vcfroot' then
        local key = string.sub(fileName, 1, -5)

        vcfData[key] = ParseVCF(xml, fileName)
    end
end

local function determineOS()
    local system = nil

    local unix = os.getenv('HOME')
    local windows = os.getenv('HOMEPATH')

    if unix then system = 'unix' end
    if windows then system = 'windows' end

    -- this guy probably has some custom ENV var set...
    if unix and windows then error('Couldn\'t identify the OS unambiguously.') end

    return system
end

local function scanDir(folder)
    local pathSeparator = '/'
    local command = 'ls -A'

    if systemOS == 'windows' then
        pathSeparator = '\\'
        command = 'dir /R /B'
    end

    local resourcePath = GetResourcePath(GetCurrentResourceName())
    local directory = resourcePath .. pathSeparator .. folder
    local i, t, popen = 0, {}, io.popen
    local pfile = popen(command .. ' "' .. directory .. '"')

    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end

    if #t == 0 then
        error('Couldn\'t find any VCF files. Are they in the correct directory?')
    end

    pfile:close()
    return t
end

local function loadFile(file)
    return LoadResourceFile(GetCurrentResourceName(), file)
end

-- NEW

local vcfVehicles = {}

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

RegisterNetEvent('els:server:requestState')
AddEventHandler('els:server:requestState', function(vehicleId)
    TriggerClientEvent('els:client:updateState', source, vehicleId, vcfVehicles[vehicleId])
end)

RegisterNetEvent('els:server:enteredVehicle')
AddEventHandler('els:server:enteredVehicle', function(vehicle, model, netVehicle)
    if not IsELSVehicle(model) then
        return
    end

    if vcfVehicles[netVehicle] then
        return
    end

    vcfVehicles[netVehicle] = {
        primary = false,
        secondary = false,
        warning = false,
        siren = 0,
    }

    TriggerClientEvent('els:client:registerVehicle', -1, netVehicle)
end)

function ResetState(netVehicle)
    vcfVehicles[netVehicle] = {
        primary = false,
        secondary = false,
        warning = false,
        siren = 0,
    }

    TriggerClientEvent('els:client:updateState', -1, netVehicle, vcfVehicles[netVehicle])
end

RegisterNetEvent('els:server:toggleSiren')
AddEventHandler('els:server:toggleSiren', function(netVehicle)
    if not vcfVehicles[netVehicle] then
        return
    end

    if vcfVehicles[netVehicle].siren <= 0 then
        vcfVehicles[netVehicle].siren = 1
        vcfVehicles[netVehicle].primary = true
        vcfVehicles[netVehicle].warning = false
    else
        vcfVehicles[netVehicle].siren = 0
    end

    TriggerClientEvent('els:client:updateState', -1, netVehicle, vcfVehicles[netVehicle])
end)

RegisterNetEvent('els:server:horn')
AddEventHandler('els:server:horn', function(netVehicle, pressed)
    if not vcfVehicles[netVehicle] then
        return
    end

    if pressed then
        if not (vcfVehicles[netVehicle].siren > 0) then
            return
        end

        if vcfVehicles[netVehicle].siren ~= 2 then
            vcfVehicles[netVehicle].siren = 2
            goto continue
        end

        if vcfVehicles[netVehicle].siren == 2 then
            vcfVehicles[netVehicle].siren = 1
            goto continue
        end
    end

    ::continue::

    TriggerClientEvent('els:client:updateState', -1, netVehicle, vcfVehicles[netVehicle])
end)


RegisterNetEvent('els:server:toggleLightPrimary')
AddEventHandler('els:server:toggleLightPrimary', function(netVehicle)
    if not vcfVehicles[netVehicle] then
        return
    end

    if vcfVehicles[netVehicle].primary then
        vcfVehicles[netVehicle].siren = 0
        vcfVehicles[netVehicle].primary = false
    else
        vcfVehicles[netVehicle].primary = true
        vcfVehicles[netVehicle].warning = false
    end

    TriggerClientEvent('els:client:updateState', -1, netVehicle, vcfVehicles[netVehicle])
end)

RegisterNetEvent('els:server:toggleLightWarning')
AddEventHandler('els:server:toggleLightWarning', function(netVehicle)
    if not vcfVehicles[netVehicle] then
        return
    end

    if vcfVehicles[netVehicle].warning then
        vcfVehicles[netVehicle].warning = false
    else
        vcfVehicles[netVehicle].siren = 0
        vcfVehicles[netVehicle].primary = false
        vcfVehicles[netVehicle].warning = true
    end

    TriggerClientEvent('els:client:updateState', -1, netVehicle, vcfVehicles[netVehicle])
end)

RegisterNetEvent('els:server:toggleLightSecondary')
AddEventHandler('els:server:toggleLightSecondary', function(netVehicle)
    if not vcfVehicles[netVehicle] then
        return
    end

    if vcfVehicles[netVehicle].secondary then
        vcfVehicles[netVehicle].secondary = false
    else
        vcfVehicles[netVehicle].secondary = true
    end

    TriggerClientEvent('els:client:updateState', -1, netVehicle, vcfVehicles[netVehicle])
end)

RegisterNetEvent('els:server:init')
AddEventHandler('els:server:init', function()
    if not vcfData then
        return
    end

    TriggerClientEvent('els:client:init', source, vcfData)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    CreateThread(function()
        while true do
            for vehicleId, vehicleData in pairs(vcfVehicles) do
                if NetworkGetEntityFromNetworkId(vehicleId) == 0 then
                    vcfVehicles[vehicleId] = nil

                    TriggerClientEvent('els:client:deregisterVehicle', -1, vehicleId)
                end
            end

            Wait(0)
        end
    end)

    local folder = 'xmlFiles'

    -- determine the server OS
    systemOS = determineOS()

    if not systemOS then
        error('Couldn\'t determine your OS! Are your running on steroids??')
    end

    for _, file in pairs(scanDir(folder)) do
        local data = loadFile(folder .. '/' .. file)

        if data then
            if pcall(function() parseObjSet(data, file) end) then
                -- no errors
                print('Parsed VCF for: ' .. file)
            else
                -- VCF is faulty, notify the user and continue
                print('VCF file ' .. file .. ' could not be parsed: is your XML valid?')
            end
        else
            print('VCF file ' .. file .. ' not found: does the file exist?')
        end
    end
end)
