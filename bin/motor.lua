local ffi = require("ffi")
local buffer = require("buffer")
require("system")
local cstr = ffi46string
local c = ffi46C
local function abort(name)
  local e = cstr(c46strerror(ffi46errno()))
  error((name or "error") .. ": " .. e)
end
local AF_INET = 2
local SOCK_STREAM = 1
local IPPROTO_TCP = 6
local INADDR_ANY = 0
local function socket()
  local fd = c46socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if fd < 0 then
    abort("socket")
  end
  local a = ffi46new("int[1]", 1)
  local n = ffi46sizeof("int")
  local x = c46setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, a, n)
  if x < 0 then
    abort("setsockopt")
  end
  return(fd)
end
local function bind(port)
  local fd = socket()
  local p = ffi46new("struct sockaddr_in[1]")
  local n = ffi46sizeof("struct sockaddr_in")
  local a = p[0]
  a46sin_family = AF_INET
  a46sin_port = c46htons(port)
  a46sin_addr46s_addr = c46htonl(INADDR_ANY)
  local _p = ffi46cast("struct sockaddr*", p)
  local x = c46bind(fd, _p, n)
  if x < 0 then
    abort("bind")
  end
  local x = c46listen(fd, 10)
  if x < 0 then
    abort("listen")
  end
  return(fd)
end
local POLLNONE = 0
local POLLIN = 1
local POLLOUT = 4
local POLLERR = 8
local POLLHUP = 16
local POLLNVAL = 32
local threads = {}
local function error63(v)
  return(v > 7)
end
local function close(fd)
  if c46close(fd) < 0 then
    return(abort("close"))
  end
end
local function active(fd)
  return(threads[fd].thread)
end
local function enter(fd, thread, final)
  local f = final or function ()
    return(close(fd))
  end
  local _x = {}
  _x.fd = fd
  _x.thread = thread
  _x.events = POLLNONE
  _x.final = f
  local x = _x
  threads[fd] = x
  return(threads[fd])
end
local function leave(fd)
  local x = threads[fd]
  x46final()
  threads[fd] = nil
  return(threads[fd])
end
local function cleanup()
  local _o = threads
  local fd = nil
  for fd in next, _o do
    local x = _o[fd]
    leave(fd)
  end
end
local function dead63(c)
  return(coroutine46status(c) == "dead")
end
local function run(t, fd)
  local b,e = coroutine46resume(t)
  if not b then
    print("error:" .. e)
  end
  if dead63(t) then
    return(leave(fd))
  end
end
local function polls()
  local ps = {}
  local _o1 = threads
  local _i1 = nil
  for _i1 in next, _o1 do
    local x = _o1[_i1]
    local p = ffi46new("struct pollfd")
    p46fd = x46fd
    p46events = x46events
    add(ps, p)
  end
  return(ps)
end
local function tick(a, n)
  local i = 0
  while i < n do
    local _id = a[i]
    local fd = _id.fd
    local r = _id.revents
    local _id1 = threads[fd]
    local v = _id1.events
    local t = _id1.thread
    if dead63(t) or error63(r) then
      leave(fd)
    else
      if v == POLLNONE or r > 0 then
        run(t, fd)
      end
    end
    i = i + 1
  end
end
local IMMEDIATE = 0
local NEVER = -1
local function timeout()
  if find(function (x)
    return(x46events == POLLNONE)
  end, threads) then
    return(IMMEDIATE)
  else
    return(NEVER)
  end
end
local function loop()
  while not empty63(threads) do
    local p = polls()
    local n = _35(p)
    local a = ffi46new("struct pollfd[?]", n, p)
    local t = timeout(p)
    c46poll(a, n, t)
    tick(a, n)
  end
end
local function start()
  local _e,_x1 = xpcall(function ()
    return(loop())
  end, _37message_handler)
  local _id2 = {_e, _x1}
  local x = _id2[1]
  local e = _id2[2]
  if e then
    print("error: " .. e)
  end
  return(cleanup())
end
local F_SETFL = 4
local O_NONBLOCK = 4
local function accept(fd)
  local _fd = c46accept(fd, nil, nil)
  if _fd < 0 then
    abort("accept")
  end
  c46fcntl(_fd, F_SETFL, O_NONBLOCK)
  return(_fd)
end
local function wait(fd, o)
  local x = threads[fd]
  local _e1
  if o == "out" then
    _e1 = POLLOUT
  else
    _e1 = POLLIN
  end
  local v = _e1
  x46events = v
  return(coroutine46yield())
end
local function listen(port, f)
  local fd = bind(port)
  local function connect()
    wait(fd)
    local _fd1 = accept(fd)
    local _f = function ()
      return(f(_fd1))
    end
    enter(_fd1, coroutine46create(_f))
    return(connect(coroutine46yield()))
  end
  return(enter(fd, coroutine46create(connect)))
end
local function read(fd, b)
  wait(fd)
  local n = buffer46space(b)
  if n > 0 then
    local p = buffer46pointer(b)
    local x = c46read(fd, p, n)
    if x < 0 then
      abort("read")
    end
    b46length = b46length + x
    return(x)
  end
end
local function receive(fd)
  local b = buffer46create()
  local n = read(fd, b)
  if n > 0 then
    return(buffer46string(b))
  end
end
local function write(fd, p, n)
  wait(fd, "out")
  local x = c46write(fd, p, n)
  if x < 0 then
    abort("send")
  end
  return(x)
end
local function send(fd, s)
  local i = 0
  local n = _35(s)
  local b = ffi46cast("const char*", s)
  while i < n do
    local x = write(fd, b + i, n - i)
    i = i + x
  end
end
return({enter = enter, write = write, read = read, send = send, active = active, listen = listen, wait = wait, start = start, receive = receive})
