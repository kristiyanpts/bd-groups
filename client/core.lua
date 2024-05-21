CreateThread(function()
    if Config.Framework == "qb" then
        Core = exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == "esx" then
        Core = exports["es_extended"]:getSharedObject()
    else
        debugPrint("Invalid framework specified in config.lua")

        return
    end

    function Notify(message, type, time)
        if Config.Framework == "qb" then
            TriggerEvent("QBCore:Notify", message, type, time)
        elseif Config.Framework == "esx" then
            TriggerEvent("esx:showNotification", message, type, time)
        else
            debugPrint("Invalid framework specified in config.lua")
        end
    end
end)
