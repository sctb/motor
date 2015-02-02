local ffi = require("ffi")
local default_size = 4096
local function create(n)
  local _u2 = n or default_size
  return({capacity = _u2, length = 0, storage = ffi["new"]("char[?]", _u2)})
end
local function extend(b, n)
  local a = create(b.capacity + n)
  ffi.copy(b.storage, a.storage, b.length)
  return(a)
end
local function pointer(b)
  return(b.storage + b.length)
end
local function space(b)
  return(b.capacity - b.length)
end
local function string(b)
  return(ffi.string(b.storage, b.length))
end
return({string = string, create = create, pointer = pointer, space = space, extend = extend})
