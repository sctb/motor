local ffi = require("ffi")
local default_size = 4096
local function allocate(n)
  return(ffi["new"]("char[?]", n))
end
local function create(n)
  local _u3 = n or default_size
  return({capacity = _u3, length = 0, storage = allocate(_u3)})
end
local function length(b)
  return(b.length)
end
local function extend(b, n)
  local _u6 = n or b.capacity * 2
  local x = allocate(_u6)
  ffi.copy(x, b.storage, b.length)
  b.storage = x
  b.capacity = _u6
end
local function full63(b)
  return(b.length == b.capacity)
end
local function pointer(b)
  return(b.storage + b.length)
end
local function space(b)
  return(b.capacity - b.length)
end
local function string(b, off, len)
  local _u11 = off or 0
  local max = b.length - _u11
  local n = min(len or max, max)
  if _u11 < b.length then
    return(ffi.string(b.storage + _u11, n))
  else
    return("")
  end
end
return({string = string, space = space, pointer = pointer, length = length, ["full?"] = full63, create = create, extend = extend})
