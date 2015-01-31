local ffi = require("ffi")
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
require("system")
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
  local _u7 = ffi.cast("struct sockaddr*", p)
  local x = c.bind(fd, _u7, n)
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
  local x = {fd = fd, thread = thread, events = POLLNONE, final = f}
  threads[fd] = x
end
local function leave(fd)
  local x = threads[fd]
  x.final()
  threads[fd] = nil
end
local function cleanup()
  local _u15 = threads
  local fd = nil
  for fd in next, _u15 do
    local _u1 = _u15[fd]
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
  local _u20 = threads
  local _u2 = nil
  for _u2 in next, _u20 do
    local x = _u20[_u2]
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
    local _u23 = a[i]
    local fd = _u23.fd
    local r = _u23.revents
    local _u24 = threads[fd]
    local v = _u24.events
    local t = _u24.thread
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
  local _u30,_u31 = xpcall(function ()
    return(loop())
  end, _37message_handler)
  local _u29 = {_u30, _u31}
  local _u3 = _u29[1]
  local e = _u29[2]
  if e then
    print("error: " .. e)
  end
  return(cleanup())
end
local F_SETFL = 4
local O_NONBLOCK = 4
local function accept(fd)
  local _u35 = c.accept(fd, nil, nil)
  if _u35 < 0 then
    abort("accept")
  end
  c.fcntl(_u35, F_SETFL, O_NONBLOCK)
  return(_u35)
end
local function wait(fd, o)
  local x = threads[fd]
  local _u43
  if o == "out" then
    _u43 = POLLOUT
  else
    _u43 = POLLIN
  end
  local v = _u43
  x.events = v
  return(coroutine.yield())
end
local function listen(port, f)
  local fd = bind(port)
  local function connect()
    wait(fd)
    local fd = accept(fd)
    local f = function ()
      return(f(fd))
    end
    enter(fd, coroutine.create(f))
    return(connect(coroutine.yield()))
  end
  return(enter(fd, coroutine.create(connect)))
end
local BUFFER_SIZE = 8192
local function receive(fd)
  wait(fd)
  local b = ffi["new"]("char[?]", BUFFER_SIZE)
  local x = c.read(fd, b, BUFFER_SIZE)
  if x < 0 then
    return(abort())
  else
    if x > 0 then
      return(cstr(b, x))
    end
  end
end
local function send(fd, b)
  local i = 0
  local n = _35(b)
  local _u42 = ffi.cast("const char*", b)
  while i < n do
    wait(fd, "out")
    local x = c.write(fd, _u42 + i, n - i)
    if x < 0 then
      abort()
    end
    i = i + x
  end
end
return({active = active, enter = enter, listen = listen, send = send, wait = wait, start = start, receive = receive})
