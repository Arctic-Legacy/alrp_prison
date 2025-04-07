local PH_L_Hand <const> = 60309
local TABLET_ANIMATION_DIRECTORY <const> = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
local TABLET_ANIMATION_NAME <const> = 'base'
local BLEND_OUT_SPEED <const> = 0.5

---@class CProcessingPoint
---@field private private { m_config: any, m_interactionPoint: any, m_tabletHandle: number, m_nearbyPlayers: table }
CProcessingPoint = lib.class('CProcessingPoint')

---Creates the a new instance of CProcessingPoint
---@param coordinates vector3
---@param interactionDistance number
function CProcessingPoint:constructor(coordinates, interactionDistance)
  --self.private.m_config = config
  self.private.m_tabletHandle = 0
  self.private.m_nearbyPlayers = {}

  self:createInteractionPoint(coordinates, interactionDistance)

  CreateThread(function(_)
    while true do
      Wait(1000)

      if self:getTabletHandle() ~= 0 then
        self:updateNearbyPlayers()
      end
    end
  end)
end

---Returns the tablet handle of the processing point.
---@return number tabletHandle
function CProcessingPoint:getTabletHandle()
  return self.private.m_tabletHandle
end

---Sets the tablet handle of the processing point.
---@param tabletHandle number
function CProcessingPoint:setTabletHandle(tabletHandle)
  self.private.m_tabletHandle = tabletHandle
end

---Get a list of processable players by the processing point
---@return table nearbyPlayers
function CProcessingPoint:getNearbyPlayers()
  return self.private.m_nearbyPlayers
end

function CProcessingPoint:updateNearbyPlayers()
  for playerIndex in pairs(self.private.m_nearbyPlayers) do
    if GetPlayerName(playerIndex) == 'Invalid' then
      self.private.m_nearbyPlayers[playerIndex] = nil
    end
  end

  local activePlayers = GetActivePlayers()

  -- Add players that have just entered our scope
  for index = 1, #activePlayers do
    local playerIndex = activePlayers[index]

    if not self.private.m_nearbyPlayers[playerIndex] then
      self.private.m_nearbyPlayers[playerIndex] = {
        source = playerIndex,
        name = GetPlayerName(playerIndex),
        job = ''
      }
    end
  end

  -- Tell the UI about our new players
  SendNUIMessage({
    type = 'setNearbyPlayers',
    players = self:getNearbyPlayers()
  })
end

---Uses the games built in notification system to display a helpful message
---@param inputType string
function CProcessingPoint:displayHelpMessage(inputType)
  BeginTextCommandDisplayHelp(inputType)
  EndTextCommandDisplayHelp(0, false, true, -1)
end

---comment
function CProcessingPoint:openTablet()
  if not lib.requestAnimDict(TABLET_ANIMATION_DIRECTORY) then
    warn('Failed to load animation directory in time')
    return
  end

  local networkTabletHandle, objectCreationError = lib.callback.await('alrp:prison:requestTabletObject', false)

  if not NetworkDoesNetworkIdExist(networkTabletHandle) then
    self:displayHelpMessage(objectCreationError)
    return
  end

  local tabletHandle = NetworkGetEntityFromNetworkId(networkTabletHandle)

  if not DoesEntityExist(tabletHandle) then
    lib.notify({
      description = objectCreationError or
      ('No object creation error but failed to convert %s into a usable object handle (To many networked objects?)')
      :format(networkTabletHandle),
      type = 'error'
    })
    return
  end

  self.private.m_tabletHandle = tabletHandle

  local playerPed = cache.ped
  local playerLeftHandBoneIndex = GetPedBoneIndex(playerPed, PH_L_Hand)

  SetCurrentPedWeapon(playerPed, `weapon_unarmed`, true)
  AttachEntityToEntity(tabletHandle, playerPed, playerLeftHandBoneIndex, 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false,
    false, false, 2, true)

  if not IsEntityPlayingAnim(playerPed, TABLET_ANIMATION_DIRECTORY, TABLET_ANIMATION_NAME, 3) then
    TaskPlayAnim(playerPed, TABLET_ANIMATION_DIRECTORY, TABLET_ANIMATION_NAME, 3.0, 3.0, -1, 49, 0, false, false, false)
  end

  RemoveAnimDict(TABLET_ANIMATION_DIRECTORY)
end

---comment
function CProcessingPoint:closeTablet()
  local playerPed = cache.ped

  if not IsEntityPlayingAnim(playerPed, TABLET_ANIMATION_DIRECTORY, TABLET_ANIMATION_NAME, 3) then
    return
  end

  StopEntityAnim(playerPed, TABLET_ANIMATION_NAME, TABLET_ANIMATION_DIRECTORY, BLEND_OUT_SPEED)
  TriggerServerEvent('alrp:prison:removeTablet', ObjToNet(self.private.m_tabletHandle))

  table.wipe(self.private.m_nearbyPlayers)
  self.private.m_tabletHandle = 0
end

-- Helper function to check if a player is restricted (e.g., police, fire, etc.)
function CProcessingPoint:isNearbyPlayerRestricted(playerIndex)
  -- Retrieve the player's job using NDCore.getRemotePlayerJob (assuming it's available)
  local playerJob = NDCore.getRemotePlayerJob(playerIndex)

  -- List of restricted jobs (e.g., police, paramedic, fire)
  local restrictedJobs = {
  }

  -- Check if the player's job is in the restricted list
  for _, restrictedJob in ipairs(restrictedJobs) do
    if playerJob == restrictedJob then
      return true  -- Player is in a restricted job
    end
  end

  return false  -- Player is not restricted
end

---comment
---@param coordinates any
---@param interactionDistance any
function CProcessingPoint:createInteractionPoint(coordinates, interactionDistance)
  local point = lib.points.new({
    coords = coordinates,
    distance = interactionDistance
  })
  local processingPoint = self

  function point:onEnter()
    processingPoint:displayHelpMessage('BEGIN_PROCESSING_PLAYER')
  end

  function point:onExit()
    ClearAllHelpMessages()
  end

  function point:nearby()
    if IsControlJustReleased(0, 51) then
      processingPoint:openTablet()

      SendNUIMessage({
        type = 'setTabletState',
        state = true
      })
      SetNuiFocus(true, true)
    end
  end

  ---@diagnostic disable-next-line: inject-field
  self.private.m_interactionPoint = point
end

---comment
function CProcessingPoint:removeInteractionPoint()
  self.private.m_interactionPoint:remove()
end