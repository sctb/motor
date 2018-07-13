local motor = require("motor")
local stream = require("stream")
local sep = "\r\n"
local sep2 = sep .. sep
local function words(x)
  return split(x, " ")
end
local function cleave(x, sep)
  local __n = search(x, sep)
  if nil63(__n) then
    return x
  else
    return {clip(x, 0, __n), clip(x, __n + _35(sep))}
  end
end
local function begin(s)
  local ____id = words(stream.line(s, sep))
  local __m = ____id[1]
  local __p = ____id[2]
  local __v = ____id[3]
  local ____x1 = {}
  ____x1.path = __p
  ____x1.method = __m
  ____x1.version = __v
  return ____x1
end
local function headers(s)
  local __x2 = {}
  local __b = stream.line(s, sep2)
  local ____o = split(__b, sep)
  local ____i = nil
  for ____i in next, ____o do
    local __l = ____o[____i]
    local ____id1 = cleave(__l, ": ")
    local __k = ____id1[1]
    local __v1 = ____id1[2]
    __x2[__k] = __v1
  end
  return __x2
end
local function body(s, n)
  return stream.take(s, n)
end
local function response(data, code)
  return "HTTP/1.1 " .. code .. sep .. "Content-Length: " .. _35(data) .. sep2 .. data
end
local function respond(s, data)
  return stream.emit(s, response(data, "200 OK"))
end
local function problem(s, data)
  return stream.emit(s, response(data, "500 Internal Server Error"))
end
local function unknown(s)
  return stream.emit(s, response("Unknown", "404 Not Found"))
end
local function serve(port, f)
  local function connect(fd)
    return f(stream.create(fd))
  end
  motor.listen(port, connect)
  return motor.start()
end
return {serve = serve, begin = begin, problem = problem, headers = headers, body = body, unknown = unknown, respond = respond}
