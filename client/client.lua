-- local function toggleNuiFrame(shouldShow)
--   SetNuiFocus(shouldShow, shouldShow)
--   SendReactMessage('setVisible', shouldShow)
-- end

-- RegisterCommand('show-nui', function()
--   toggleNuiFrame(true)
--   debugPrint('Show NUI frame')
-- end)

-- RegisterNUICallback('hideFrame', function(_, cb)
--   toggleNuiFrame(false)
--   debugPrint('Hide NUI frame')
--   cb({})
-- end)

-- RegisterNUICallback('getClientData', function(data, cb)
--   debugPrint('Data sent by React', json.encode(data))

-- -- Lets send back client coords to the React frame for use
--   local curCoords = GetEntityCoords(PlayerPedId())

--   local retData <const> = { x = curCoords.x, y = curCoords.y, z = curCoords.z }
--   cb(retData)
-- end)

-- * Credit to - https://github.com/Project-Sloth/ps-playergroups

CurrentJobStage = "WAITING"
GroupId = -1
IsGroupLeader = false
GroupBlips = {}

-- Finds a blip by the name of the group blip and returns its index in the table.
local function FindBlipByName(name)
  for i = 1, #GroupBlips do
    if GroupBlips[i] ~= nil then
      if GroupBlips[i]["name"] == name then
        return i
      end
    end
  end

  return false
end

RegisterNuiCallback('groups:get-status', function(_, cb)
  if GroupId then
    local groupInfo = lib.callback.await('yseries:server:groups:get', false, GroupId)

    cb(groupInfo)
    return
  end

  cb(nil)
end)

RegisterNuiCallback('groups:get-active', function(_, cb)
  if GroupId then
    local groups = lib.callback.await('yseries:server:groups:get-active', false)

    cb(groups)
    return
  end

  cb(nil)
end)

RegisterNUICallback('groups:get-requests', function(groupId, cb)
  local requests = lib.callback.await('yseries:server:groups:get-requests', false, groupId)

  cb(requests)
end)

RegisterNuiCallback('groups:request-join', function(groupId, cb)
  local send = lib.callback.await('yseries:server:groups:request-join', false, groupId)

  cb(send)
end)

RegisterNuiCallback('groups:accept-join', function(data, cb)
  local accepted = lib.callback.await('yseries:server:groups:accept-join', false, data)

  cb(accepted)
end)

RegisterNuiCallback('groups:deny-join', function(data, cb)
  local denied = lib.callback.await('yseries:server:groups:deny-join', false, data)

  cb(denied)
end)

RegisterNuiCallback('groups:kick-member', function(playerId, cb)
  local kicked = lib.callback.await('yseries:server:groups:kick-member', false, playerId, GroupId)

  cb(kicked)
end)

RegisterNuiCallback('groups:leave', function(groupId, cb)
  TriggerServerEvent("yseries:server:groups:leave", groupId)

  CurrentJobStage = "WAITING"
  GroupId = -1
  IsGroupLeader = false
  for i = 1, #GroupBlips do
    RemoveBlip(GroupBlips[i]["blip"])
    GroupBlips[i] = nil
  end

  cb(true)
end)

RegisterNUICallback('groups:create', function(groupName, cb)
  local groupInfo = lib.callback.await("yseries:server:groups:request-create", false, groupName)

  if groupInfo?.groupId then
    CurrentJobStage = "WAITING"
    GroupId = groupInfo.groupId
    IsGroupLeader = true

    local group = lib.callback.await('yseries:server:groups:get', false, GroupId)

    cb(group)
    return
  end

  cb(groupInfo)
end)

RegisterNetEvent("yseries:client:groups:remove-blip", function(name)
  local i = FindBlipByName(name)
  if i then
    local blip = GroupBlips[i]["blip"]
    SetBlipRoute(blip, false)
    RemoveBlip(blip)
    GroupBlips[i] = nil
  end
end)

RegisterNetEvent('yseries:client:groups:create-blip', function(name, data)
  if data == nil then
    debugPrint("Invalid Data was passed to the create blip event")
    return
  end

  if FindBlipByName(name) then
    TriggerEvent("yseries:client:groups:remove-blip", name)
  end

  local blip = nil
  if data.entity then
    blip = AddBlipForEntity(data.entity)
  elseif data.netId then
    blip = AddBlipForEntity(NetworkGetEntityFromNetworkId(data.netId))
  elseif data.radius then
    blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z, data.radius)
  else
    blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
  end

  if data.color == nil then data.color = 1 end
  if data.alpha == nil then data.alpha = 255 end

  if not data.radius then
    if data.sprite == nil then data.sprite = 1 end
    if data.scale == nil then data.scale = 0.7 end
    if data.label == nil then data.label = "NO LABEL FOUND" end

    SetBlipSprite(blip, data.sprite)
    SetBlipScale(blip, data.scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(data.label)
    EndTextCommandSetBlipName(blip)
  end

  SetBlipColour(blip, data.color)
  SetBlipAlpha(blip, data.alpha)

  if data.route then
    SetBlipRoute(blip, true)
    if not data.routeColor then data.routeColor = data.color end
    SetBlipRouteColour(blip, data.routeColor)
  end

  GroupBlips[#GroupBlips + 1] = { name = name, blip = blip }
end)

RegisterNetEvent("yseries:client:groups:update-leader", function()
  IsGroupLeader = true

  SendUIAction('groups:make-leader', true)
end)

RegisterNetEvent('yseries:client:groups:update-group-data', function()
  local groupInfo = lib.callback.await('yseries:server:groups:get', false, GroupId)
  SendUIAction('groups:update-group-data', groupInfo)
end)

RegisterNetEvent("yseries:client:groups:group-destroy", function()
  CurrentJobStage = "WAITING"
  GroupId = -1
  IsGroupLeader = false
end)

RegisterNetEvent("yseries:client:groups:join", function(groupId)
  GroupId = groupId

  SendUIAction('groups:join-accepted', groupId)
end)

RegisterNetEvent("yseries:client:groups:remove-pending-join", function(groupId)
  SendUIAction('groups:remove-pending-join', groupId)
end)

RegisterNetEvent('yseries:client:groups:get-remove-from-group', function()
  SendUIAction('groups:get-remove-from-group')
end)

RegisterNetEvent('yseries:client:groups:update-job-stage', function(stage)
  CurrentJobStage = stage

  SendUIAction('groups:update-job-stage', stage)
end)

RegisterNetEvent('yseries:client:groups:refresh-feed', function()
  SendUIAction('groups:refresh-feed')
end)

-- * Exports
-- Returns Client side job stage
exports("GetJobStage", function()
  return CurrentJobStage
end)

-- Returns Clients current groupId
exports("GetGroupId", function()
  return GroupId
end)

-- Returns if the Client is the group leader.
exports("IsGroupLeader", function()
  return IsGroupLeader
end)
