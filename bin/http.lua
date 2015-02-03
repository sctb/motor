local motor = require("motor")
local stream = require("stream")
local sep = "\r\n"
local sep2 = sep .. sep
local function words(x)
  return(split(x, " "))
end
local function cleave(x, sep)
  local n = search(x, sep)
  if nil63(n) then
    return(x)
  else
    return({clip(x, 0, n), clip(x, n + _35(sep))})
  end
end
local function start(s)
  local _u6 = words(stream.line(s, sep))
  local m = _u6[1]
  local p = _u6[2]
  local v = _u6[3]
  return({path = p, method = m, version = v})
end
local function headers(s)
  local x = {}
  local b = stream.line(s, sep2)
  local _u8 = split(b, sep)
  local _u1 = nil
  for _u1 in next, _u8 do
    local l = _u8[_u1]
    local _u10 = cleave(l, ": ")
    local k = _u10[1]
    local v = _u10[2]
    x[k] = v
  end
  return(x)
end
local function body(s, n)
  return(stream.take(s, n))
end
local function response(data, code)
  return("HTTP/1.1 " .. code .. sep .. "Content-Length: " .. _35(data) .. sep2 .. data)
end
local function respond(s, data)
  return(stream.emit(s, response(data, "200 OK")))
end
local function problem(s, data)
  return(stream.emit(s, response(data, "500 Internal Server Error")))
end
local function unknown(s)
  return(stream.emit(s, response("Unknown", "404 Not Found")))
end
local function serve(port, f)
  local function connect(fd)
    return(f(stream.create(fd)))
  end
  motor.listen(port, connect)
  return(motor.start())
end
return({headers = headers, unknown = unknown, problem = problem, serve = serve, body = body, start = start, respond = respond})
