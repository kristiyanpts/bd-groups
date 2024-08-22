CreateThread(function()
    if Config.Framework == "qb" then
        Core = exports["qb-core"]:GetCoreObject()
    elseif Config.Framework == "esx" then
        Core = exports["es_extended"]:getSharedObject()
    else
        debugPrint("Invalid framework specified in config.lua")

        return
    end

    function GetPlayerName(source)
        if Config.Framework == "qb" then
            return Core.Functions.GetPlayer(source)?.PlayerData?.charinfo?.firstname,
                Core.Functions.GetPlayer(source)?.PlayerData?.charinfo?.lastname
        elseif Config.Framework == "esx" then
            return Core.GetPlayerFromId(source)?.firstname, Core.GetPlayerFromId(source)?.lastname
        else
            debugPrint("Invalid framework specified in config.lua")
        end
    end
end)
