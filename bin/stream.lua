local motor = require("motor")
local buffer = require("buffer")
local function create(fd)
  local __x = {}
  __x.fd = fd
  __x.buffer = buffer.create()
  __x.pos = 0
  return(__x)
end
local function space(s)
  return(buffer.space(s.buffer))
end
local function length(s)
  return(buffer.length(s.buffer))
end
local function full63(s)
  return(buffer["full?"](s.buffer))
end
local function extend(s, n)
  return(buffer.extend(s.buffer, n))
end
local function read(s)
  return(motor.read(s.fd, s.buffer))
end
local function string(s, n)
  return(buffer.string(s.buffer, s.pos, n))
end
local function fill(s)
  if full63(s) then
    extend(s)
  end
  return(read(s) > 0)
end
local function before(s, pat)
  local _n = nil
  while nil63(_n) do
    local _x1 = string(s)
    local _m = search(_x1, pat)
    if nil63(_m) then
      if not fill(s) then
        _n = -1
      end
    else
      _n = _m
    end
  end
  if _n >= 0 then
    local _x2 = string(s, _n)
    s.pos = s.pos + _n
    return(_x2)
  end
end
local function line(s, pat)
  local _p = pat or "\n"
  local _x3 = before(s, _p)
  s.pos = s.pos + _35(_p)
  return(_x3)
end
local function take(s, n)
  if space(s) < n then
    extend(s, n)
  end
  while length(s) - s.pos < n do
    if not fill(s) then
      break
    end
  end
  local _x4 = string(s, n)
  s.pos = s.pos + _35(_x4)
  return(_x4)
end
local function emit(s, b)
  return(motor.send(s.fd, b))
end
return({create = create, line = line, take = take, emit = emit})
