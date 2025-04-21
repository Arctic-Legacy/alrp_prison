local IS_SERVER <const> = IsDuplicityVersion()
local DEFAULT_CONFIG <const> = {
  TABLET_MODEL = `prop_cs_tablet`,
  MAX_JAIL_SENTENCE = 60 * 1000,
  MIN_JAIL_SENTENCE = 10 * 1000,
  PROCESSING_POINTS = IS_SERVER and {} or {
    CProcessingPoint:new("Paleto Bay Sheriff's Office", vector3(-440.81, 6010.61, 27.58), 5),
    CProcessingPoint:new("Sandy Shores Sheriff's Office", vector3(1850.19, 3688.06, 34.66), 5),
    CProcessingPoint:new("Mission Row PD", vector3(480.97, -986.99, 27.53), 5),
    CProcessingPoint:new("Davis PD", vector3(363.43, -1602.50, 30.06), 5),
    CProcessingPoint:new("Vespucci PD", vector3(-1325.46, -1527.71, 4.42), 5),
    CProcessingPoint:new("Rockford Hills PD", vector3(-558.99, -104.62, 34.41), 5),
    CProcessingPoint:new("Vinewood PD", vector3(626.25, -3.93, 77.50), 5),
    CProcessingPoint:new("Zancudo Jail", vector3(-2236.19, 3484.79, 30.24), 5),
    CProcessingPoint:new("SAST Paleto Branch", vector3(79.94, 6564.65, 26.43), 5),
    CProcessingPoint:new("SAST HQ", vector3(2618.4, 5318.26, 40.09), 5)
  },
  LAW_ENFORCEMENT_GROUPS = {
    'lspd',
    'sahp'
  }
}

---@class CConfigStore
---@field private private { m_tabletModel: number, m_maximumPrisonSentence: number, m_minimumPrisonSentence: number, m_processingPoints: CProcessingPoint[], m_lawEnforcementGroups: table }
CConfigStore = lib.class('CConfigStore')

function CConfigStore:constructor()
  self.private.m_tabletModel = DEFAULT_CONFIG.TABLET_MODEL --[[@as number backticks get converted to a hash]]
  self.private.m_processingPoints = {}
  self.private.m_maximumPrisonSentence = DEFAULT_CONFIG.MAX_JAIL_SENTENCE

  self:setTabletModel()
  self:setMaximumPrisonSentence()
  self:setMinimumPrisonSentence()
  self:setLawEnforcementGroups()

  if not IS_SERVER then
    self:setProcessingPoints()
  end
end

--- Returns the tablet model used in the configuration.
---@return number tabletModel
function CConfigStore:getTabletModel()
  return self.private.m_tabletModel
end

--- Sets the tablet model based on a convar or the default value.
function CConfigStore:setTabletModel()
  local tabletModel = GetConvar('alrp:prison:tabletModel', 'prop_cs_tablet')

  if tabletModel == 'prop_cs_tablet' then
    self.private.m_tabletModel = DEFAULT_CONFIG.TABLET_MODEL --[[@as number backticks get converted to a hash]]
    return
  end

  self.private.m_tabletModel = GetHashKey(tabletModel)
end

--- Returns the maximum jail sentence duration in milliseconds.
---@return number maximumPrisonSentence
function CConfigStore:getMaximumPrisonSentence()
  return self.private.m_maximumPrisonSentence
end

--- Sets the maximum jail sentence based on a convar
function CConfigStore:setMaximumPrisonSentence()
  local maximumJailSentence = GetConvarInt('alrp:prison:maximumJailSentence', DEFAULT_CONFIG.MAX_JAIL_SENTENCE)

  self.private.m_maximumPrisonSentence = maximumJailSentence
end

--- Returns the minimum jail sentence duration in milliseconds.
---@return number minimumPrisonSentence
function CConfigStore:getMinimumPrisonSentence()
  return self.private.m_minimumPrisonSentence
end

--- Sets the minimum jail sentence based on a convar.
function CConfigStore:setMinimumPrisonSentence()
  local minimumPrisonSentence = GetConvarInt('alrp:prison:minimumPrisonSentence', DEFAULT_CONFIG.MIN_JAIL_SENTENCE)

  self.private.m_minimumPrisonSentence = minimumPrisonSentence
end

--- Returns a list of processing points for prisoners.
---@return CProcessingPoint[] processingPoints
function CConfigStore:getProcessingPoints()
  if IS_SERVER then
    warn('CConfigStore:getProcessingPoints is not available on the server')
  end

  return self.private.m_processingPoints
end

--- Sets the processing points from a convar or defaults if not provided.
function CConfigStore:setProcessingPoints()
  if IS_SERVER then
    warn('CConfigStore:setProcessingPoints is not available on the server')
    return
  end

  local rawProcessingPoints = GetConvar('alrp:prison:processingPoints', 'default')

  if rawProcessingPoints == 'default' then
    warn('alrp:prison:processingPoints is not set, using the default configuration. To resolve this, add `exec @alrp_prison/config.cfg` to your server configuration file.')
    self.private.m_processingPoints = DEFAULT_CONFIG.PROCESSING_POINTS
    return
  end

  local processingPointsDecoded = json.decode(rawProcessingPoints)

  if not processingPointsDecoded then
    warn('alrp:prison:processingPoints contains malformed data. Please correct the configuration and restart the resource.')
    self.private.m_processingPoints = DEFAULT_CONFIG.PROCESSING_POINTS
    return
  end

  for processingPointName, processingPointData in pairs(processingPointsDecoded) do
    local coordinate = processingPointData.coordinate
    local coordinateVectorized = table.vectorize(coordinate)

    if not coordinateVectorized then
      warn(('Skipped adding processing point %s as its coordinate could not be vectorized.'):format(processingPointName))
      goto continue
    end

    table.insert(self.private.m_processingPoints, CProcessingPoint:new(processingPointName, coordinateVectorized, 5))

    ::continue::
  end
end

--- Returns a list of law enforcement groups (e.g., {'sahp', 'lspd'}).
---@return table lawEnforcementGroups
function CConfigStore:getLawEnforcementGroups()
  return self.private.m_lawEnforcementGroups
end

--- Sets the law enforcement groups from a convar or defaults if not provided.
function CConfigStore:setLawEnforcementGroups()
  self.private.m_lawEnforcementGroups = {}

  local rawLawEnforcementGroups = GetConvar('alrp:prison:lawEnforcementGroups', 'default')

  if rawLawEnforcementGroups == 'default' then
    warn('alrp:prison:lawEnforcementGroups is unset falling back to default configuration. To resolve this, add `exec @alrp_prison/config.cfg` to your server configuration file.')
    self.private.m_lawEnforcementGroups = DEFAULT_CONFIG.lawEnforcementGroups
    return
  end

  local decodedLawEnforcementGroups = json.decode(rawLawEnforcementGroups)

  if not decodedLawEnforcementGroups then
    warn('alrp:prison:lawEnforcementGroups contains malformed data. Please correct the configuration and restart the resource.')
    self.private.m_lawEnforcementGroups = DEFAULT_CONFIG.lawEnforcementGroups
    return
  end

  for index = 1, #decodedLawEnforcementGroups do
    local group = decodedLawEnforcementGroups[index]

    self.private.m_lawEnforcementGroups[group:lower()] = true
  end
end
