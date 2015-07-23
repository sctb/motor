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
local function begin(s)
  local _id = words(stream46line(s, sep))
  local m = _id[1]
  local p = _id[2]
  local v = _id[3]
  local _x1 = {}
  _x1.path = p
  _x1.method = m
  _x1.version = v
  return(_x1)
end
local function headers(s)
  local x = {}
  local b = stream46line(s, sep2)
  local _o = split(b, sep)
  local _i = nil
  for _i in next, _o do
    local l = _o[_i]
    local _id1 = cleave(l, ": ")
    local k = _id1[1]
    local v = _id1[2]
    x[k] = v
  end
  return(x)
end
local function body(s, n)
  return(stream46take(s, n))
end
local function response(data, code)
  return("HTTP/1.1 " .. code .. sep .. "Content-Length: " .. _35(data) .. sep2 .. data)
end
local function respond(s, data)
  return(stream46emit(s, response(data, "200 OK")))
end
local function problem(s, data)
  return(stream46emit(s, response(data, "500 Internal Server Error")))
end
local function unknown(s)
  return(stream46emit(s, response("Unknown", "404 Not Found")))
end
local function serve(port, f)
  local function connect(fd)
    return(f(stream46create(fd)))
  end
  motor46listen(port, connect)
  return(motor46start())
end
return({headers = headers, begin = begin, problem = problem, serve = serve, body = body, unknown = unknown, respond = respond})
