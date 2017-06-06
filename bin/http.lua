local motor = require("motor")
local stream = require("stream")
local sep = "\r\n"
local sep2 = sep .. sep
local function words(x)
  return(split(x, " "))
end
local function cleave(x, sep)
  local _n = search(x, sep)
  if nil63(_n) then
    return(x)
  else
    return({clip(x, 0, _n), clip(x, _n + _35(sep))})
  end
end
local function begin(s)
  local __id = words(stream.line(s, sep))
  local _m = __id[1]
  local _p = __id[2]
  local _v = __id[3]
  local __x1 = {}
  __x1.method = _m
  __x1.path = _p
  __x1.version = _v
  return(__x1)
end
local function headers(s)
  local _x2 = {}
  local _b = stream.line(s, sep2)
  local __o = split(_b, sep)
  local __i = nil
  for __i in next, __o do
    local _l = __o[__i]
    local __id1 = cleave(_l, ": ")
    local _k = __id1[1]
    local _v1 = __id1[2]
    _x2[_k] = _v1
  end
  return(_x2)
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
return({begin = begin, headers = headers, body = body, respond = respond, problem = problem, unknown = unknown, serve = serve})
