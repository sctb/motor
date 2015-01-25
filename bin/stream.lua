local motor = require("motor")
local function create(fd)
  return({fd = fd, pos = 0, buffer = ""})
end
local function fill(s)
  local b = motor.receive(s.fd)
  if b then
    s.buffer = s.buffer .. b
    return(true)
  end
end
local function before(s, pat)
  local i = nil
  while nil63(i) do
    local n = search(s.buffer, pat, s.pos)
    if nil63(n) then
      if not fill(s) then
        i = -1
      end
    else
      i = n
    end
  end
  if i >= 0 then
    local _u4 = s.pos
    s.pos = i
    return(clip(s.buffer, _u4, i))
  end
end
local function line(s, pat)
  local p = pat or "\n"
  local b = before(s, p)
  s.pos = s.pos + _35(p)
  return(b)
end
local function amount(s, n)
  while _35(s.buffer) - s.pos < n do
    if not fill(s) then
      break
    end
  end
  local b = clip(s.buffer, s.pos)
  s.pos = s.pos + _35(b)
  return(b)
end
local function emit(s, b)
  return(motor.send(s.fd, b))
end
return({line = line, amount = amount, create = create, emit = emit})
