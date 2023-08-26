ELS = {}
ELS.Initialized = false
ELS.ShowModiforce = false
ELS.ELSVehicles = {}
ELS.ELSData = nil

-- local ELS = exports['mixx-els']:GetELSObject()
exports('GetELSObject', function()
    return ELS
end)
