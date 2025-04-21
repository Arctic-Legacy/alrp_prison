---comment
---@param vectorTable VectorTable
---@return false|vector3
function table.vectorize(vectorTable)
  local x, y, z = vectorTable?.x, vectorTable?.y, vectorTable?.z

  if not x or not y or not z then
    return false
  end

  local xType, yType, zType = type(x), type(y), type(z)

  if xType ~= 'number' then
    if xType ~= 'string' then
      return false
    end

    local numericX = tonumber(x)

    if not numericX then
      return false
    end

    x = numericX
  end

  if yType ~= 'number' then
    if yType ~= 'string' then
      return false
    end

    local numericY = tonumber(y)

    if not numericY then
      return false
    end

    y = numericY
  end

  if zType ~= 'number' then
    if zType ~= 'string' then
      return false
    end

    local numericZ = tonumber(z)

    if not numericZ then
      return false
    end

    z = numericZ
  end

  return vector3(x, y, z)
end
