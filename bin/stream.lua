local motor = require("motor")
local buffer = require("buffer")
local function create(fd)
  local _x = {}
  _x.fd = fd
  _x.pos = 0
  _x.buffer = buffer46create()
  return(_x)
end
local function space(s)
  return(buffer46space(s46buffer))
end
local function length(s)
  return(buffer46length(s46buffer))
end
local function full63(s)
  return(buffer46full63(s46buffer))
end
local function extend(s, n)
  return(buffer46extend(s46buffer, n))
end
local function read(s)
  return(motor46read(s46fd, s46buffer))
end
local function string(s, n)
  return(buffer46string(s46buffer, s46pos, n))
end
local function fill(s)
  if full63(s) then
    extend(s)
  end
  return(read(s) > 0)
end
local function before(s, pat)
  local n = nil
  while nil63(n) do
    local x = string(s)
    local m = search(x, pat)
    if nil63(m) then
      if not fill(s) then
        n = -1
      end
    else
      n = m
    end
  end
  if n >= 0 then
    local _x1 = string(s, n)
    s46pos = s46pos + n
    return(_x1)
  end
end
local function line(s, pat)
  local p = pat or "\n"
  local x = before(s, p)
  s46pos = s46pos + _35(p)
  return(x)
end
local function take(s, n)
  if space(s) < n then
    extend(s, n)
  end
  while length(s) - s46pos < n do
    if not fill(s) then
      break
    end
  end
  local x = string(s, n)
  s46pos = s46pos + _35(x)
  return(x)
end
local function emit(s, b)
  return(motor46send(s46fd, b))
end
return({line = line, emit = emit, create = create, take = take})
