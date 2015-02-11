local ffi = require("ffi")
local default_size = 4096
local function allocate(n)
  return(ffi["new"]("char[?]", n))
end
local function create(n)
  local _n = n or default_size
  return({capacity = _n, length = 0, storage = allocate(_n)})
end
local function length(b)
  return(b.length)
end
local function extend(b, n)
  local _e
  if n then
    _e = b.capacity + n
  else
    _e = b.capacity * 2
  end
  local _n1 = _e
  local x = allocate(_n1)
  ffi.copy(x, b.storage, b.length)
  b.storage = x
  b.capacity = _n1
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
local function string(b, i, n)
  local _i = i or 0
  local max = b.length - _i
  local _n2 = min(n or max, max)
  if _i < b.length then
    return(ffi.string(b.storage + _i, _n2))
  else
    return("")
  end
end
return({string = string, space = space, pointer = pointer, length = length, ["full?"] = full63, create = create, extend = extend})
