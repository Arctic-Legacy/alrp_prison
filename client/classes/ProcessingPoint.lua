local PH_L_Hand <const> = 60309
local TABLET_ANIMATION_DIRECTORY <const> = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
local TABLET_ANIMATION_NAME <const> = 'base'
local BLEND_OUT_SPEED <const> = 0.5
local PLAYER_CONTROL <const> = 0
local INPUT_CONTEXT <const> = 51 -- E/DPAD LEFT

---@class CProcessingPoint
---@field private private { m_name: string, m_coordinate: vector3, m_interactionDistance: number, m_interactionPoint: any, m_tabletHandle: number, m_nearbyPlayers: table }
CProcessingPoint = lib.class('CProcessingPoint')

---Creates the a new instance of CProcessingPoint
---@param coordinate vector3
---@param interactionDistance number
function CProcessingPoint:constructor(name, coordinate, interactionDistance)
  self.private.m_name = name
  self.private.m_coordinate = coordinate
  self.private.m_interactionDistance = interactionDistance or 5
  self.private.m_interactionPoint = false
  self.private.m_tabletHandle = 0
  self.private.m_nearbyPlayers = {}

  CreateThread(function(_)
    while true do
      Wait(1000)

      if self:getTabletHandle() ~= 0 then
        self:updateNearbyPlayers()
      end
    end
  end)
end

---Returns the name of the processing point
function CProcessingPoint:getName()
  return self.private.m_name
end

function CProcessingPoint:getCoordinate()
  return self.private.m_coordinate
end

function CProcessingPoint:getInteractionDistance()
  return self.private.m_interactionDistance
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

function CProcessingPoint:removeStalePlayers()
  local nearbyPlayers = self:getNearbyPlayers()

  for playerIndex in pairs(nearbyPlayers) do
    if GetPlayerName(playerIndex) == 'Invalid' then
      self.private.m_nearbyPlayers[playerIndex] = nil
    end
  end
end

function CProcessingPoint:updateNearbyPlayers()
  self:removeStalePlayers()

  local activePlayers = GetActivePlayers()

  for index = 1, #activePlayers do
    local playerIndex = activePlayers[index]

    if not self.private.m_nearbyPlayers[playerIndex] then
      self.private.m_nearbyPlayers[playerIndex] = {
        source = GetPlayerServerId(playerIndex),
        name = GetPlayerName(playerIndex),
        job = '',
        ignored = IsPlayerLawEnforcement(playerIndex)
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

function CProcessingPoint:openTablet()
  if not lib.requestAnimDict(TABLET_ANIMATION_DIRECTORY) then
    warn('Failed to load animation directory in time skipping tablet animation')
    return
  end

  local networkTabletHandle, tabletCreationError = lib.callback.await('alrp:prison:requestTabletObject', false)

  if not NetworkDoesNetworkIdExist(networkTabletHandle) then
    self:displayHelpMessage(tabletCreationError)
    return
  end

  local tabletHandle = NetworkGetEntityFromNetworkId(networkTabletHandle)

  if not DoesEntityExist(tabletHandle) then
    warn('Failed to convert network tablet handle to local handle skipping tablet animation.')
    return
  end

  self:setTabletHandle(tabletHandle)

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

function CProcessingPoint:createInteractionPoint()
  local point = lib.points.new({
    coords = self:getCoordinate(),
    distance = self:getInteractionDistance()
  })

  local processingPoint = self

  function point:onEnter()
    processingPoint:displayHelpMessage('BEGIN_PROCESSING_PLAYER')
  end

  function point:onExit()
    ClearAllHelpMessages()
  end

  function point:nearby()
    if IsControlJustReleased(PLAYER_CONTROL, INPUT_CONTEXT) and not processingPoint:getTabletHandle() ~= 0 then
      processingPoint:openTablet()

      SendNUIMessage({
        type = 'setTabletState',
        state = true
      })
      SetNuiFocus(true, true)
    end
  end

  self.private.m_interactionPoint = point
end

function CProcessingPoint:removeInteractionPoint()
  if self.private.m_interactionPoint then
    self.private.m_interactionPoint:remove()
    self.private.m_interactionPoint = nil
  end
end