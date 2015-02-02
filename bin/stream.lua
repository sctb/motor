local motor = require("motor")
local buffer = require("buffer")
local function create(fd)
  return({fd = fd, pos = 0, buffer = buffer.create()})
end
local function fill(s)
  if buffer["full?"](s.buffer) then
    buffer.extend(s.buffer)
  end
  return(motor.read(s.fd, s.buffer) > 0)
end
local function before(s, pat)
  local n = nil
  while nil63(n) do
    local x = buffer.string(s.buffer, s.pos)
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
    local i = s.pos
    s.pos = s.pos + n
    return(buffer.string(s.buffer, i, n))
  end
end
local function line(s, pat)
  local p = pat or "\n"
  local b = before(s, p)
  s.pos = s.pos + _35(p)
  return(b)
end
local function amount(s, n)
  local b = s.buffer
  if buffer.space(b) < n then
    buffer.extend(b, n)
  end
  while buffer.length(b) - s.pos < n do
    if not fill(s) then
      break
    end
  end
  local x = buffer.string(b, s.pos, s.pos + n)
  s.pos = s.pos + _35(x)
  return(x)
end
local function emit(s, b)
  return(motor.send(s.fd, b))
end
return({line = line, amount = amount, create = create, emit = emit})
