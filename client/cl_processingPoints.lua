local config = CConfigStore:new()

---Check if the specified player is in the law enforcement groups
---Not passing any player will check the local player
---@param playerIndex number?
---@return boolean
function IsPlayerLawEnforcement(playerIndex)
  local playerJob

  if playerIndex then
    playerJob = NDCore.getRemotePlayerJob(playerIndex)
  else
    playerJob = NDCore.getPlayer()?.job
  end

  if type(playerJob) ~= 'string' or not config:getLawEnforcementGroups()[playerJob:lower()] then
    return false
  end

  return true
end

---Unregisters processing points
local function unregisterProcessingPoints()
  local processingPoints = config:getProcessingPoints()

  ClearAllHelpMessages()

  for processingPointIndex = 1, #processingPoints do
    local processingPoint = processingPoints[processingPointIndex]

    processingPoint:removeInteractionPoint()
  end
end

---Registers processing points
local function registerProcessingPoints()
  local processingPoints = config:getProcessingPoints()

  for processingPointIndex = 1, #processingPoints do
    local processingPoint = processingPoints[processingPointIndex]

    processingPoint:createInteractionPoint()
  end
end

RegisterNUICallback('closeTablet', function(_, callback)
  local processingPoints = config:getProcessingPoints()
  local processingPointsLength = #processingPoints

  if processingPointsLength < 1 then
    warn('Received closeTablet from NUI but no processing points have been registered')
  end

  for processingPointIndex = 1, processingPointsLength do
    local processingPoint = processingPoints[processingPointIndex]

    if processingPoint:getTabletHandle() ~= 0 then
      processingPoint:closeTablet()
      break
    end
  end

  callback('ok')
  SetNuiFocus(false, false)
end)

RegisterNetEvent("ND:characterUnloaded", function(_)
  unregisterProcessingPoints()
end)

RegisterNetEvent('ND:characterLoaded', function(character)
  if not IsPlayerLawEnforcement() then
    return
  end

  registerProcessingPoints()
end)

RegisterNetEvent("ND:updateCharacter", function(character)
  if not IsPlayerLawEnforcement() then
    unregisterProcessingPoints()
    return
  end

  registerProcessingPoints()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
  if cache.resource ~= resourceName then
    return
  end

  AddTextEntry('BEGIN_PROCESSING_PLAYER', 'Press ~INPUT_CONTEXT~ to begin processing nearby players')
  AddTextEntry('NO_TABLET_PERMISSION', '')
  AddTextEntry('FAILED_TO_CREATE_TABLET', '')

  if not IsPlayerLawEnforcement() then
    return
  end

  registerProcessingPoints()
end)