local ffi = require("ffi")
local buffer = require("buffer")
ffi.cdef[[
int socket(int domain, int type, int protocol);
int fcntl(int fildes, int cmd, ...);

typedef int socklen_t;

int bind(
  int socket,
  const struct sockaddr *address,
  socklen_t address_len);

int listen(int socket, int backlog);

int accept(
  int socket,
  struct sockaddr *restrict address,
  socklen_t *restrict address_len);

int setsockopt(
  int socket,
  int level,
  int option_name,
  const void *option_value,
  socklen_t option_len);

typedef uint8_t sa_family_t;
typedef uint16_t in_port_t;
typedef uint32_t in_addr_t;

struct in_addr {
  in_addr_t     s_addr;
};

uint16_t htons(uint16_t hostshort);
uint32_t htonl(uint32_t hostlong);

typedef unsigned int nfds_t;

struct pollfd {
  int   fd;
  short events;
  short revents;
};

int poll(struct pollfd *fds, nfds_t nfds, int timeout);
int close(int fildes);

char *strerror(int errnum);

typedef unsigned int size_t;
typedef int ssize_t;

ssize_t read(int fildes, void *buf, size_t nbyte);
ssize_t write(int fildes, const void *buf, size_t nbyte);
]]
require("socket")
local cstr = ffi.string
local c = ffi.C
local function abort(name)
  local e = cstr(c.strerror(ffi.errno()))
  error((name or "error") .. ": " .. e)
end
local AF_INET = 2
local SOCK_STREAM = 1
local IPPROTO_TCP = 6
local INADDR_ANY = 0
local function socket()
  local fd = c.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if fd < 0 then
    abort("socket")
  end
  local a = ffi["new"]("int[1]", 1)
  local n = ffi.sizeof("int")
  local x = c.setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, a, n)
  if x < 0 then
    abort("setsockopt")
  end
  return(fd)
end
local function bind(port)
  local fd = socket()
  local p = ffi["new"]("struct sockaddr_in[1]")
  local n = ffi.sizeof("struct sockaddr_in")
  local a = p[0]
  a.sin_family = AF_INET
  a.sin_port = c.htons(port)
  a.sin_addr.s_addr = c.htonl(INADDR_ANY)
  local _p = ffi.cast("struct sockaddr*", p)
  local x = c.bind(fd, _p, n)
  if x < 0 then
    abort("bind")
  end
  local x = c.listen(fd, 10)
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
  if c.close(fd) < 0 then
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
  x.final()
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
  return(coroutine.status(c) == "dead")
end
local function run(t, fd)
  local b,e = coroutine.resume(t)
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
    local p = ffi["new"]("struct pollfd")
    p.fd = x.fd
    p.events = x.events
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
    return(x.events == POLLNONE)
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
    local a = ffi["new"]("struct pollfd[?]", n, p)
    local t = timeout(p)
    c.poll(a, n, t)
    tick(a, n)
  end
end
local function start()
  local _x1 = nil
  local _msg = nil
  local _trace = nil
  local _e
  if xpcall(function ()
    _x1 = loop()
    return(_x1)
  end, function (m)
    _trace = debug.traceback()
    local _e1
    if string63(m) then
      _e1 = clip(m, search(m, ": ") + 2)
    else
      local _e2
      if nil63(m) then
        _e2 = ""
      else
        _e2 = str(m)
      end
      _e1 = _e2
    end
    _msg = _e1
    return(_msg)
  end) then
    _e = {true, _x1}
  else
    _e = {false, {stack = _trace, message = _msg}}
  end
  local _id2 = _e
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
  local _fd = c.accept(fd, nil, nil)
  if _fd < 0 then
    abort("accept")
  end
  c.fcntl(_fd, F_SETFL, O_NONBLOCK)
  return(_fd)
end
local function wait(fd, o)
  local x = threads[fd]
  local _e3
  if o == "out" then
    _e3 = POLLOUT
  else
    _e3 = POLLIN
  end
  local v = _e3
  x.events = v
  return(coroutine.yield())
end
local function listen(port, f)
  local fd = bind(port)
  local function connect()
    wait(fd)
    local _fd1 = accept(fd)
    local _f = function ()
      return(f(_fd1))
    end
    enter(_fd1, coroutine.create(_f))
    return(connect(coroutine.yield()))
  end
  return(enter(fd, coroutine.create(connect)))
end
local function read(fd, b)
  wait(fd)
  local n = buffer.space(b)
  if n > 0 then
    local p = buffer.pointer(b)
    local x = c.read(fd, p, n)
    if x < 0 then
      abort("read")
    end
    b.length = b.length + x
    return(x)
  end
end
local function receive(fd)
  local b = buffer.create()
  local n = read(fd, b)
  if n > 0 then
    return(buffer.string(b))
  end
end
local function write(fd, p, n)
  wait(fd, "out")
  local x = c.write(fd, p, n)
  if x < 0 then
    abort("send")
  end
  return(x)
end
local function send(fd, s)
  local i = 0
  local n = _35(s)
  local b = ffi.cast("const char*", s)
  while i < n do
    local x = write(fd, b + i, n - i)
    i = i + x
  end
end
return({enter = enter, write = write, send = send, read = read, active = active, listen = listen, wait = wait, start = start, receive = receive})
