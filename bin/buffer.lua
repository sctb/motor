local ffi = require("ffi")
local default_size = 4096
local function allocate(n)
  return ffi["new"]("char[?]", n)
end
local function create(n)
  local __n = n or default_size
  local ____x = {}
  ____x.capacity = __n
  ____x.length = 0
  ____x.storage = allocate(__n)
  return ____x
end
local function length(b)
  return b.length
end
local function extend(b, n)
  local __e
  if n then
    __e = b.capacity + n
  else
    __e = b.capacity * 2
  end
  local __n1 = __e
  local __x1 = allocate(__n1)
  ffi.copy(__x1, b.storage, b.length)
  b.storage = __x1
  b.capacity = __n1
  return b.capacity
end
local function full63(b)
  return b.length == b.capacity
end
local function pointer(b)
  return b.storage + b.length
end
local function space(b)
  return b.capacity - b.length
end
local function string(b, i, n)
  local __i = i or 0
  local __max = b.length - __i
  local __n2 = min(n or __max, __max)
  if __i < b.length then
    return ffi.string(b.storage + __i, __n2)
  else
    return ""
  end
end
return {string = string, space = space, pointer = pointer, length = length, ["full?"] = full63, create = create, extend = extend}
