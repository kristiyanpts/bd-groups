local function toggleNuiFrame(shouldShow)
  SetNuiFocus(shouldShow, shouldShow)
  SendReactMessage('setVisible', shouldShow)
end

RegisterNUICallback('hideFrame', function(_, cb)
  toggleNuiFrame(false)
  debugPrint('Hide NUI frame')
  cb({})
end)

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

RegisterNuiCallback('fetchGroupStatus', function(_, cb)
  if GroupId then
    local groupInfo = lib.callback.await('bd-groups:server:groups:get', false, GroupId)

    cb(groupInfo)
    return
  end

  cb(nil)
end)

RegisterNuiCallback('fetchMaxMembers', function(_, cb)
  cb(Config.MaxMembers)
end)

RegisterNuiCallback('fetchGroups', function(_, cb)
  if GroupId then
    local groups = lib.callback.await('bd-groups:server:groups:get-active', false)

    cb(groups)
    return
  end

  cb(nil)
end)

RegisterNUICallback('fetchRequests', function(groupId, cb)
  local requests = lib.callback.await('bd-groups:server:groups:get-requests', false, groupId)

  cb(requests)
end)

RegisterNuiCallback('requestJoin', function(groupId, cb)
  local send = lib.callback.await('bd-groups:server:groups:request-join', false, groupId)

  cb(send)
end)

RegisterNuiCallback('acceptRequest', function(data, cb)
  local accepted = lib.callback.await('bd-groups:server:groups:accept-join', false, data)

  cb(accepted)
end)

RegisterNuiCallback('denyRequest', function(data, cb)
  local denied = lib.callback.await('bd-groups:server:groups:deny-join', false, data)

  cb(denied)
end)

RegisterNuiCallback('kickMember', function(playerId, cb)
  local kicked = lib.callback.await('bd-groups:server:groups:kick-member', false, playerId, GroupId)

  cb(kicked)
end)

RegisterNuiCallback('leaveGroup', function(groupId, cb)
  TriggerServerEvent("bd-groups:server:groups:leave", groupId)

  CurrentJobStage = "WAITING"
  GroupId = -1
  IsGroupLeader = false
  for i = 1, #GroupBlips do
    RemoveBlip(GroupBlips[i]["blip"])
    GroupBlips[i] = nil
  end

  cb(true)
end)

RegisterNUICallback('createGroup', function(groupName, cb)
  local groupInfo = lib.callback.await("bd-groups:server:groups:request-create", false, groupName)

  if groupInfo?.groupId then
    CurrentJobStage = "WAITING"
    GroupId = groupInfo.groupId
    IsGroupLeader = true

    local group = lib.callback.await('bd-groups:server:groups:get', false, GroupId)

    cb(group)
    return
  end

  cb(groupInfo)
end)

RegisterNetEvent("bd-groups:client:groups:remove-blip", function(name)
  local i = FindBlipByName(name)
  if i then
    local blip = GroupBlips[i]["blip"]
    SetBlipRoute(blip, false)
    RemoveBlip(blip)
    GroupBlips[i] = nil
  end
end)

RegisterNetEvent('bd-groups:client:groups:create-blip', function(name, data)
  if data == nil then
    debugPrint("Invalid Data was passed to the create blip event")
    return
  end

  if FindBlipByName(name) then
    TriggerEvent("bd-groups:client:groups:remove-blip", name)
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

RegisterNetEvent("bd-groups:client:groups:update-leader", function()
  IsGroupLeader = true

  SendReactMessage('makeLeader')
end)

RegisterNetEvent('bd-groups:client:groups:update-group-data', function()
  local groupInfo = lib.callback.await('bd-groups:server:groups:get', false, GroupId)
  SendReactMessage('updateGroupData', groupInfo)
end)

RegisterNetEvent("bd-groups:client:groups:group-destroy", function()
  CurrentJobStage = "WAITING"
  GroupId = -1
  IsGroupLeader = false
end)

RegisterNetEvent("bd-groups:client:groups:join", function(groupId)
  GroupId = groupId

  SendReactMessage('joinAccepted')
end)

RegisterNetEvent("bd-groups:client:groups:remove-pending-join", function(groupId)
  SendReactMessage('removePendingJoin')
end)

RegisterNetEvent('bd-groups:client:groups:get-remove-from-group', function()
  SendReactMessage('getRemovedFromGroup')
end)

RegisterNetEvent('bd-groups:client:groups:update-job-stage', function(stage)
  CurrentJobStage = stage

  SendReactMessage('updateJobStage', stage)
end)

RegisterNetEvent('bd-groups:client:groups:refresh-feed', function()
  SendReactMessage('refreshFeed')
end)

RegisterNetEvent('bd-groups:client:send-notification', function(notifData)
  Notify(notifData.text, "primary", notifData.time)
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

RegisterCommand('show-nui', function()
  toggleNuiFrame(true)
  SendReactMessage('refreshFeed')
  debugPrint('Show NUI frame')
end)

if Config.ImportInPhone then
  local key = "bd-groups"

  CreateThread(function()
    while GetResourceState(Config.Phone) ~= "started" do
      Wait(500)
    end

    local function AddApp()
      if Config.Phone == "yseries" then
        local phoneResourceName = "yseries"

        local dataLoaded = exports[phoneResourceName]:GetDataLoaded()
        while not dataLoaded do
          Wait(500)
          dataLoaded = exports[phoneResourceName]:GetDataLoaded()
        end


        exports[phoneResourceName]:AddCustomApp({
          key = key,
          name = "Групи",
          defaultApp = false,
          ui = "https://cfx-nui-" .. GetCurrentResourceName() .. "/ui/build/index.html", -- built version
          -- ui = "http://localhost:3000", -- dev version
          icon = {
            yos = "https://cdn-icons-png.flaticon.com/512/2314/2314912.png",    -- YPhone OS icon.
            humanoid = "https://cdn-icons-png.flaticon.com/512/566/566312.png", -- YFlip OS icon.
          },
        })
      elseif Config.Phone == "qs-smartphone-pro" then
        local ui = 'https://cfx-nui-' .. GetCurrentResourceName() .. '/ui/build/'

        exports[Config.Phone]:addCustomApp({
          app = 'groups',
          image = ui .. 'icon.png',
          ui = ui .. 'index.html',
          label = 'Groups',
          job = false,
          blockedJobs = {},
          timeout = 5000,
          creator = 'Quasar Store',
          category = 'social',
          isGame = false,
          description = 'This is your first testing app, I hope you manage to create incredible things!',
          age = '16+',
          extraDescription = {
            {
              header = 'Test',
              head = 'Test application',
              image =
              'https://media.istockphoto.com/photos/abstract-background-wallpaper-picture-id952039286?b=1&k=20&m=952039286&s=170667a&w=0&h=LmOcMt7FHxFUAr2bOSfTUPV9sQhME6ABtAYLM0cMkR4=',
              footer = 'This is your first testing app, I hope you manage to create incredible things!'
            }
          }
        })
      else
        debugPrint("Invalid phone type")
      end
    end

    AddApp()

    AddEventHandler("onResourceStart", function(resource)
      if resource == Config.Phone then
        AddApp()
      end
    end)

    RegisterNuiCallback('get-nui-data', function(_, cb)
      cb('I came from client.lua')
    end)

    AddEventHandler("onResourceStop", function(resource)
      if resource == GetCurrentResourceName() then
        if Config.Phone == "yseries" then
          exports[Config.Phone]:RemoveCustomApp(key)
        else
          if Config.Phone == "qs-smartphone-pro" then
            exports[Config.Phone]:removeCustomApp('groups')
          else
            debugPrint("Invalid phone type")
          end
        end
      end
    end)
  end)
else
  RegisterCommand('groups', function()
    toggleNuiFrame(true)
    SendReactMessage('refreshFeed')
    debugPrint('Show NUI frame')
  end)
end
