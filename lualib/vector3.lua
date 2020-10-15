--[[
Documentation:
https://developer.roblox.com/en-us/api-reference/datatype/vector3

Extra Info:
Cannot use any other constructor functions other than vector3.new() because of enums.
This version can also add and subtract numbers to vectors

Made by HiddenKaiser on 9/11/20 at 2:30 pm
--]]

local vector3 = {__type = "vector3"}
local mt = {__index = vector3}

-- Math operations

-- Constructs a new vector3 using the given x, y, and z components.
function vector3.new(x, y, z, dont_unit)
  local self = {x = x or 0, y = y or 0, z = z or 0}
  setmetatable(self, mt)
  self.magnitude = self:get_magnitude()
  if not dont_unit then
    self.unit = vector3.new(
      self.x / self.magnitude,
      self.y / self.magnitude,
      self.z / self.magnitude,
      true)
  end
  self:setup_aliases()
  return self
end

function mt.__mul(a, b) -- When the vector gets multiplied
  if (type(a) == "number") then
    -- a is a scalar, b is a vector
    local scalar, vector = a, b
    return vector3.new(scalar * vector.x, scalar * vector.y, scalar * vector.z)
  elseif (type(b) == "number") then
    -- a is a vector, b is a scalar
    local vector, scalar = a, b
    return vector3.new(vector.x * scalar, vector.y * scalar, vector.z * scalar)
  elseif (a.__type and a.__type == "vector3" and b.__type and b.__type == "vector3") then
    -- both a and b are vectors
    return vector3.new(a.x * b.x, a.y * b.y, a.z * b.z)
  end
end

function mt.__div(a, b) -- When the vector gets divided
  if (type(a) == "number") then
    -- a is a scalar, b is a vector
    local scalar, vector = a, b
    return vector3.new(scalar / vector.x, scalar / vector.y, scalar / vector.z)
  elseif (type(b) == "number") then
    -- a is a vector, b is a scalar
    local vector, scalar = a, b
    return vector3.new(vector.x / scalar, vector.y / scalar, vector.z / scalar)
  elseif (a.__type and a.__type == "vector3" and b.__type and b.__type == "vector3") then
    -- both a and b are vectors
    return vector3.new(a.x / b.x, a.y / b.y, a.z / b.z)
  end
end

function mt.__add(a, b) -- When the vector gets added
  if (type(a) == "number") then
    -- a is a scalar, b is a vector
    local scalar, vector = a, b
    return vector3.new(scalar + vector.x, scalar + vector.y, scalar + vector.z)
  elseif (type(b) == "number") then
    -- a is a vector, b is a scalar
    local vector, scalar = a, b
    return vector3.new(vector.x + scalar, vector.y + scalar, vector.z + scalar)
  elseif (a.__type and a.__type == "vector3" and b.__type and b.__type == "vector3") then
    -- both a and b are vectors
    return vector3.new(a.x + b.x, a.y + b.y, a.z + b.z)
  end
end

function mt.__sub(a, b) -- When the vector gets subtracted
  if (type(a) == "number") then
    -- a is a scalar, b is a vector
    local scalar, vector = a, b
    return vector3.new(scalar - vector.x, scalar - vector.y, scalar - vector.z)
  elseif (type(b) == "number") then
    -- a is a vector, b is a scalar
    local vector, scalar = a, b
    return vector3.new(vector.x - scalar, vector.y - scalar, vector.z - scalar)
  elseif (a.__type and
					a.__type == "vector3" and b.__type and b.__type == "vector3") then
    -- both a and b are vectors
    return vector3.new(a.x - b.x, a.y - b.y, a.z - b.z)
  end
end

-- Math operations End

-- Misc functions

function mt.__tostring(t) -- when tostring is called on the vector
  return ("(".. t.x .. ", " .. t.y .. ", " ..t.z ..")");
end;

function vector3:floor() -- math.floor the vector
  local x,y,z = self.x,self.y,self.z
  return vector3.new(math.floor(x), math.floor(y), math.floor(z))
end

function vector3:get_magnitude() -- Get magnitude, (can also just use Vector.magnitude)
    return self.magnitude or
			math.abs( math.sqrt( (self.x)^2 + (self.y)^2 + (self.z)^2 ) )
end

function vector3:lerp(b,percent) -- lerp two vectors
  if b and percent then
      local result = self + ((b - self) * percent)
      return result
  end
end

function vector3:dot(b) -- Get dot product of vector b
  local a = self
  local dot = ( (a.x*b.x) + (a.y*b.y) + (a.z*b.z) )
  return dot
end

function vector3:cross(b) -- Get cross product of vector b
  local a = self
  return vector3.new(
      (a.y*b.z) - (a.z*b.y),
      (a.z*b.x) - (a.x*b.z),
      (a.x*b.y) - (a.y*b.x)
  )
end

-- Returns true if the given vector3 falls within the epsilon radius of this vector3.
function vector3:fuzzy_eq(v1, epsilon)
  local v2 = self
  local function fuzzyEq(a, b, _epsilon)
    return a == b or math.abs(a - b) <= (math.abs(a) + 1) * _epsilon
  end

  if not fuzzyEq(v1.x, v2.x, epsilon) then  return false  end
  if not fuzzyEq(v1.y, v2.y, epsilon) then  return false  end
  if not fuzzyEq(v1.z, v2.z, epsilon) then  return false  end
  return true
end

function vector3:setup_aliases() -- Sets up aliases for functions and properties
  self.magnitude = self.magnitude
  -- self.unit = self.unit
  -- self.X = self.x;  self.Y = self.y;  self.Z = self.z; -- xyz to XYZ

  function vector3:is_close(...)  return self:fuzzy_eq(...)  end -- alias of fuzzy_eq
  -- function vector3:lerp(...)  return self:lerp(...)  end -- alias of lerp
  -- function vector3:dot(...)  return self:dot(...)  end -- alias of
  -- function vector3:cross(...)  return self:cross(...)  end -- alias of
end
