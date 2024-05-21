local Groups = {}
local Players = {}
local Requests = {}
local GroupData = {}

local notification = {
    app = 'groups',
    sound = 'default',
    title = 'Groups',
    timeout = 3000
}

local function formatCharacterName(playerSource)
    local firstName, lastName = GetPlayerName(playerSource)

    return firstName .. " " .. lastName
end

local function findGroupByMember(playerSource)
    if Players[playerSource] then
        for group, data in pairs(Groups) do
            local members = data["members"]
            if members["leader"] == playerSource then
                return group
            else
                for i = 1, #members["helpers"] do
                    if members["helpers"][i] == playerSource then
                        return group
                    end
                end
            end
        end

        return 0
    else
        return 0
    end
end

-- Returns group's job status.
local function getJobStatus(groupId)
    if not groupId then
        debugPrint("GetJobStatus was sent an invalid groupId :" .. groupId)
        return
    end

    return Groups[groupId]["status"]
end

local function getGroupLeader(groupId)
    if not groupId then
        debugPrint("GetGroupLeader was sent an invalid groupId: " .. groupId)
        return nil
    end

    return Groups[groupId]["members"]["leader"]
end

local function isGroupLeader(groupId, playerSource)
    if not groupId or not playerSource then
        debugPrint("isGroupLeader was sent an invalid groupId: " .. groupId)
        return nil
    end

    return Groups[groupId]["members"]["leader"] == playerSource
end

local function getGroupMembers(groupId)
    if groupId == nil then
        debugPrint("getGroupMembers was sent an invalid groupId :" .. groupId)
        return nil
    end

    local groupMembers = {}
    groupMembers[#groupMembers + 1] = Groups[groupId]["members"]["leader"]
    for _, v in pairs(Groups[groupId]["members"]["helpers"]) do
        groupMembers[#groupMembers + 1] = v
    end

    return groupMembers
end

-- Gets number of players in a group.
local function getGroupMembersCount(groupId)
    if groupId == nil then
        debugPrint("getGroupSize was sent an invalid groupId :" .. groupId)
        return
    end

    if Groups[groupId]["members"]["helpers"] == nil or 0 then
        return 1
    else
        return #Groups[groupId]["members"]["helpers"] + 1
    end
end

-- Sets a group job status.
local function setJobStatus(groupId, status)
    if groupId == nil then
        debugPrint("setJobStatus was sent an invalid groupId :" .. groupId)
        return
    end

    Groups[groupId]["status"] = status

    local m = getGroupMembers(groupId)
    if not m then return end

    for i = 1, #m do
        TriggerClientEvent("bd-groups:client:groups:update-job-stage", m[i], status)
    end
end

local function changeGroupLeader(groupId)
    local m = Groups[groupId]['members']['helpers'] or {}
    local l = getGroupLeader(groupId)
    local leaderFound = false
    local leader = 0

    for k, v in pairs(m) do
        if not leaderFound then
            if Groups[groupId]["members"]["helpers"][k] ~= l then
                Groups[groupId]["members"]["leader"] = v
                table.remove(Groups[groupId]["members"]["helpers"], k)
                leaderFound = true
                leader = v
            end
        end
    end

    if leader ~= 0 then
        TriggerClientEvent("bd-groups:client:groups:update-leader", leader)

        notification.data = {
            label = 'promotedToLeader',
        }
        TriggerClientEvent('bd-groups:client:send-notification', leader,
            notification)
    end

    return leaderFound
end

-- Pushes current group data to the specified groupId to aLL members.
local function updateGroupData(groupId)
    local members = getGroupMembers(groupId)
    if members == nil then return end

    for i = 1, #members do
        TriggerClientEvent("bd-groups:client:groups:update-group-data", members[i])
    end
end

-- Remove all group members.
local function removeGroupMembers(groupId)
    local g = Groups[groupId]

    for i = 1, #g["members"]["helpers"] do
        Players[g["members"]["helpers"][i]] = nil
        Groups[groupId]["members"]["helpers"][i] = nil
    end

    Players[g["members"]["leader"]] = nil
end

-- Destroy a group object.
local function destroyGroup(groupId)
    local m = getGroupMembers(groupId)
    if m == nil then return end

    removeGroupMembers(groupId)
    for i = 1, #m do
        TriggerClientEvent("bd-groups:client:groups:group-destroy", m[i])
    end

    TriggerClientEvent('bd-groups:client:groups:refresh-feed', -1)

    Groups[groupId] = nil
end

local function createBlipForGroup(groupId, name, data)
    if groupId == nil then
        debugPrint("CreateBlipForGroup was sent an invalid groupId :" .. groupId)
        return
    end

    local members = getGroupMembers(groupId)
    if not members then return end

    for i = 1, #members do
        TriggerClientEvent("bd-groups:client:groups:create-blip", members[i], name, data)
    end
end

-- Remove a blip for everyone in a group with the matching blip name.
local function removeBlipForGroup(groupId, name)
    if groupId == nil then
        debugPrint("RemoveBlipForGroup was sent an invalid groupId :" .. groupId)
        return
    end

    local members = getGroupMembers(groupId)
    if not members then return end

    for i = 1, #members do
        TriggerClientEvent("bd-groups:client:groups:remove-blip", members[i], name)
    end
end

-- Triggers event for each member of a group. Args are optional.
local function sendGroupEvent(groupId, event, args)
    if groupId == nil then return debugPrint("SendGroupEvent was sent an invalid groupId :" .. groupId) end
    if event == nil then return debugPrint("Invalid event was passed to GroupEvent") end

    local members = getGroupMembers(groupId)
    if not members then return end

    for i = 1, #members do
        if args ~= nil then
            TriggerClientEvent(event, members[i], table.unpack(args))
        else
            TriggerClientEvent(event, members[i])
        end
    end
end

local function setGroupData(groupId, key, data)
    if groupId == nil then return debugPrint("SetGroupData was sent an invalid groupId") end
    if key == nil then return debugPrint("SetGroupData was sent an invalid key") end

    GroupData[groupId][key] = data
end

local function getGroupData(groupId, key)
    if groupId == nil then return debugPrint("GetGroupData was sent an invalid groupId") end
    if key == nil then return debugPrint("GetGroupData was sent an invalid key") end

    if GroupData[groupId][key] == nil then
        return false
    else
        return GroupData[groupId][key]
    end
end

local function destroyGroupData(groupId, key)
    if groupId == nil then return debugPrint("DestroyGroupData was sent an invalid groupId") end
    if key == nil then return debugPrint("DestroyGroupData was sent an invalid key") end

    GroupData[groupId][key] = nil
end

-- Adds player to specified group.
local function addPlayerToGroup(player, groupId)
    if not Players[player] then
        if Groups[groupId] then
            Players[player] = true
            local g = Groups[groupId]["members"]["helpers"]
            g[#g + 1] = player

            updateGroupData(groupId)

            return true
        else
            debugPrint("Group doesn't exist")
        end
    else
        debugPrint("Player is already in a group")
    end

    return false
end

local function removePlayerFromGroup(playerSource, groupId)
    if Players[playerSource] then
        if Groups[groupId] then
            local g = Groups[groupId]["members"]["helpers"]

            if Groups[groupId]["members"]["leader"] == playerSource then
                if changeGroupLeader(groupId) then
                    Players[playerSource] = nil
                    Wait(10)

                    updateGroupData(groupId)

                    TriggerEvent("bd-groups:server:groups:player-left", playerSource, true, groupId)
                else
                    Players[playerSource] = nil
                    destroyGroup(groupId)
                end
            else
                for k, v in pairs(g) do
                    if playerSource == v then
                        table.remove(Groups[groupId]["members"]["helpers"], k)

                        TriggerClientEvent('bd-groups:client:groups:group-destroy', v)

                        TriggerEvent("bd-groups:server:groups:player-left", playerSource, true, groupId)

                        Players[playerSource] = nil
                    end
                end
                Wait(10)

                updateGroupData(groupId)
            end
        end
    end
end

local function notifyGroup(groupId, message, timeout)
    local members = getGroupMembers(groupId)
    if not members then return end

    notification.text = message
    notification.timeout = timeout or 3000
    notification.data = nil

    for i = 1, #members do
        TriggerClientEvent('bd-groups:client:send-notification', members[i], notification)
    end
end

local function doesGroupExist(groupId)
    if Groups[groupId] then return true end
    return false
end


-- * ^ FUNCTIONS ^ * --

-- Removes player from group when they leave the server.
AddEventHandler('playerDropped', function(reason)
    local src = source

    local groupId = findGroupByMember(src)
    if groupId > 0 then
        removePlayerFromGroup(src, groupId) -- This function now handles changing leader as well.
    end
end)

-- * ^ NET EVENTS ^ * --

-- Leave the speicifed group.
RegisterNetEvent('bd-groups:server:groups:leave', function(groupId)
    local src = source
    removePlayerFromGroup(src, groupId)
end)

-- Destroy a group object.
-- This is called when the leader leaves the group.
RegisterServerEvent("bd-groups:server:groups:destroy", function()
    local src = source
    local g = findGroupByMember(src)

    if g > 0 then
        destroyGroup(g)
    else
        debugPrint("Unable to destory group as it doesn't exist.")
    end
end)

-- * ^ NET EVENTS ^ * --

-- * ^ CALLBACKS  ^ * --
lib.callback.register('bd-groups:server:groups:get', function(src, groupId)
    local group = Groups[groupId]
    if not group then return nil end

    local groupData = {
        id = group.id,
        displayName = group.displayName,
        status = group.status,
        isLeader = group.members.leader == src,
    }

    local members = {
        leader = { id = group.members.leader, name = formatCharacterName(group.members.leader) },
        helpers = {},
    }

    for i = 1, #group.members.helpers do
        members.helpers[#members.helpers + 1] = {
            id = group.members.helpers[i],
            name = formatCharacterName(group
                .members.helpers[i])
        }
    end

    groupData.members = members

    return groupData
end)

lib.callback.register('bd-groups:server:groups:get-members', function(_, groupId)
    local groupMembers = {}
    local members = getGroupMembers(groupId)
    if members == nil then return end

    for i = 1, #members do
        groupMembers[#groupMembers + 1] = { id = members[i], name = formatCharacterName(members[i]) }
    end

    return groupMembers
end)

-- Player sends a requested asking the server if they can create a group.
lib.callback.register('bd-groups:server:groups:request-create', function(src, groupName)
    if not Players[src] then
        Players[src] = true

        local groupId = #Groups + 1
        Groups[groupId] = {
            id = groupId,
            status = "WAITING",
            displayName = groupName,
            members = {
                leader = src,
                helpers = {},
            }
        }

        GroupData[groupId] = {}

        TriggerClientEvent('bd-groups:client:groups:refresh-feed', -1)

        return { groupId = groupId, name = formatCharacterName(src), playerSource = src }
    else
        -- TriggerClientEvent("QBCore:Notify", src, "You are already in a group", "error")
        return false
    end
end)

-- Get all active groups currently in the server.
lib.callback.register('bd-groups:server:groups:get-active', function(_)
    local activeGroups = {}
    for k, v in pairs(Groups) do
        if Groups[k] ~= nil then
            if v.status == "WAITING" then
                local groupData = {
                    id = v.id,
                    displayName = v.displayName,
                    status = v.status,
                    members = v.members
                }

                table.insert(activeGroups, groupData)
            end
        end
    end

    return activeGroups
end)

lib.callback.register('bd-groups:server:groups:request-join', function(src, groupId)
    local group = Groups[groupId]
    if not group then return end

    local lead = Groups[groupId]["members"]["leader"]
    if not Players[src] then
        if Groups[groupId] then
            if #Groups[groupId]["members"]["helpers"] + 1 < Config.MaxMembers then
                if Requests[groupId] == nil then
                    Requests[groupId] = {}
                end

                table.insert(Requests[groupId], src)

                notification.data = {
                    label = 'joinRequest',
                }

                TriggerClientEvent('bd-groups:client:send-notification', lead,
                    notification)

                return { success = true }
            else
                return { success = false, message = 'The group is full' }
            end
        else
            return { success = false, message = "That group doesn't exist" }
            -- TriggerClientEvent("QBCore:Notify", src, "That group doesn't exist", "error")
        end
    else
        return { success = false, message = "You already have a request pending" }
        -- TriggerClientEvent("QBCore:Notify", src, "You already have a request pending", "error")
    end
end)

lib.callback.register("bd-groups:server:groups:accept-join", function(_, data)
    local groupId = data.groupId
    local playerId = data.playerId

    if addPlayerToGroup(playerId, groupId) then
        for k, v in pairs(Requests[groupId]) do
            if v == playerId then
                Requests[groupId][k] = nil
            end
        end

        notification.data = {
            label = 'requestAccepted',
        }
        TriggerClientEvent('bd-groups:client:send-notification', playerId,
            notification)

        TriggerClientEvent("bd-groups:client:groups:join", playerId, groupId)

        updateGroupData(groupId)

        return true
    end

    return false
end)

lib.callback.register("bd-groups:server:groups:deny-join", function(_, data)
    local groupId = data.groupId
    local playerId = data.playerId

    for k, v in pairs(Requests[groupId]) do
        if v == playerId then
            Requests[groupId][k] = nil
        end
    end

    notification.data = {
        label = 'joinDenied',
    }
    TriggerClientEvent('bd-groups:client:send-notification', playerId,
        notification)

    TriggerClientEvent('bd-groups:client:groups:remove-pending-join', playerId, groupId)

    return true
end)

lib.callback.register("bd-groups:server:groups:kick-member", function(_, playerId, groupId)
    removePlayerFromGroup(playerId, groupId)

    notification.data = {
        label = 'kicked',
    }
    TriggerClientEvent('bd-groups:client:send-notification', playerId,
        notification)

    TriggerClientEvent('bd-groups:client:groups:get-remove-from-group', playerId)

    updateGroupData(groupId)
end)

lib.callback.register("bd-groups:server:groups:get-requests", function(_, groupId)
    local requests = {}
    if Requests[groupId] then
        for _, v in pairs(Requests[groupId]) do
            table.insert(requests, { name = formatCharacterName(v), id = v })
        end

        return requests
    end

    return requests
end)

-- * ^ CALLBACKS  ^ * --

-- * Exports
exports("GetGroupLeader", getGroupLeader)
exports("IsGroupLeader", isGroupLeader)
exports('GetGroupMembers', getGroupMembers)
exports("FindGroupByMember", findGroupByMember)
exports('GetJobStatus', getJobStatus)
exports('SetJobStatus', setJobStatus)
exports('GetGroupMembersCount', getGroupMembersCount)
exports('CreateBlipForGroup', createBlipForGroup)
exports('RemoveBlipForGroup', removeBlipForGroup)
exports("SendGroupEvent", sendGroupEvent)
exports("SetGroupData", setGroupData)
exports("GetGroupData", getGroupData)
exports("DestroyGroupData", destroyGroupData)
exports('NotifyGroup', notifyGroup)
exports('DoesGroupExist', doesGroupExist)
