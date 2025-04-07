local processingPoints = {}

---comment
local function unregisterProcessingPoints()
  local processingPointsLength = #processingPoints

  if processingPointsLength < 1 then
    return
  end

  ClearAllHelpMessages()

  for index = 1, processingPointsLength do
    local processingPoint = processingPoints[index]

    processingPoint:removeInteractionPoint()
  end

  table.wipe(processingPoints)
end

---comment
local function registerProcessingPoints()
  if #processingPoints >= 1 then
    unregisterProcessingPoints()
  end

  for index = 1, #config.accessLocation do
    local interactionCoordinates = config.accessLocation[index]

    table.insert(processingPoints, CProcessingPoint:new(interactionCoordinates, 5))
  end
end

-- make this not a global or put it in a util file
function isJobAllowed(jobName)
  local allowedJobs = {
    ['sahp'] = true,
    ['bcso'] = true
  }

  return allowedJobs[jobName] ~= nil
end

RegisterNUICallback('closeTablet', function(_, callback)
  local processingPointsLength = #processingPoints

  if processingPointsLength < 1 then
    warn('Received closeTablet from NUI but no processing points have been registered')
  end

  for processingPointIndex = 1, #processingPoints do
    local processingPoint = processingPoints[processingPointIndex]

    if processingPoint:getTabletHandle() ~= 0 then
      processingPoint:closeTablet()
      break -- There should only ever be one tablet open at a time
    end
  end

  callback('ok')
  SetNuiFocus(false, false)
end)

RegisterNetEvent("ND:characterUnloaded", function(_)
  unregisterProcessingPoints()
end)

RegisterNetEvent('ND:characterLoaded', function(character)
  local characterJob = character.job

  if not isJobAllowed(characterJob) then
    return
  end

  registerProcessingPoints()
end)

RegisterNetEvent("ND:updateCharacter", function(character)
  local characterJob = character.job

  if not isJobAllowed(characterJob) then

    if #processingPoints >= 1 then
      unregisterProcessingPoints()
    end

    return
  end

  registerProcessingPoints()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
  if cache.resource ~= resourceName then
    return
  end

  AddTextEntry('BEGIN_PROCESSING_PLAYER', 'Press ~INPUT_CONTEXT~ to begin processing nearby players')

  local character = NDCore.getPlayer()

  if not character then
    return
  end

  local characterJob = character.job

  if not isJobAllowed(characterJob) then
    return
  end

  registerProcessingPoints()
end)