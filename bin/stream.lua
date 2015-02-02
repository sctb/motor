local motor = require("motor")
local buffer = require("buffer")
local function create(fd)
  return({fd = fd, pos = 0, buffer = buffer.create()})
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
    local _u10 = string(s, n)
    s.pos = s.pos + n
    return(_u10)
  end
end
local function line(s, pat)
  local p = pat or "\n"
  local x = before(s, p)
  s.pos = s.pos + _35(p)
  return(x)
end
local function amount(s, n)
  if space(s) < n then
    extend(s, n)
  end
  while length(s) - s.pos < n do
    if not fill(s) then
      break
    end
  end
  local x = string(s, n)
  s.pos = s.pos + _35(x)
  return(x)
end
local function emit(s, b)
  return(motor.send(s.fd, b))
end
return({line = line, amount = amount, create = create, emit = emit})
