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
            local FirstName, LastName = Core.GetPlayerFromId(source)?.variables?.firstName, Core.GetPlayerFromId(source)?.variables?.lastName
            if FirstName == nil or LastName == nil then
                FirstName, LastName = Core.GetPlayerFromId(source)?.firstname, Core.GetPlayerFromId(source)?.lastname
            elseif FirstName == nil or LastName == nil then
                FirstName, LastName = Core.GetPlayerFromId(source)?.firstName, Core.GetPlayerFromId(source)?.lastName
            end
            return FirstName, LastName
        else
            debugPrint("Invalid framework specified in config.lua")
        end
    end
end)
