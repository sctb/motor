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

typedef uint8_t sa_family_t;
typedef uint16_t in_port_t;
typedef uint32_t in_addr_t;

struct in_addr {
  in_addr_t     s_addr;
};

struct sockaddr_in {
  uint8_t               sin_len;
  sa_family_t           sin_family;
  in_port_t             sin_port;
  struct in_addr        sin_addr;
  char                  sin_zero[8];
};

uint32_t htonl(uint32_t hostlong);
uint16_t htons(uint16_t hostshort);
char * inet_ntoa(struct in_addr in);

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
local cstr = ffi.string
local c = ffi.C
local function abort(name)
  local e = cstr(c.strerror(ffi.errno()))
  error((name or "error") .. ": " .. e)
end
local PF_INET = 2
local AF_INET = 2
local INADDR_ANY = 0
local SOCK_STREAM = 1
local IPPROTO_TCP = 6
local function socket()
  local fd = c.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP)
  if fd < 0 then
    abort("socket")
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
  a.sin_addr.s_addr = INADDR_ANY
  local _u5 = ffi.cast("struct sockaddr*", p)
  local x = c.bind(fd, _u5, n)
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
local function dead63(c)
  return(coroutine.status(c) == "dead")
end
local function run(t, fd)
  local b,e = coroutine.resume(t)
  if not b then
    print("error:" .. " " .. string(e))
  end
  if dead63(t) then
    return(leave(fd))
  end
end
local function polls()
  local ps = {}
  local _u15 = threads
  local _u1 = nil
  for _u1 in next, _u15 do
    local x = _u15[_u1]
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
    local _u18 = a[i]
    local fd = _u18.fd
    local r = _u18.revents
    local _u19 = threads[fd]
    local v = _u19.events
    local t = _u19.thread
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
local function start()
  while not empty63(threads) do
    local p = polls()
    local n = _35(p)
    local a = ffi["new"]("struct pollfd[?]", n, p)
    local t = timeout(p)
    c.poll(a, n, t)
    tick(a, n)
  end
end
local F_SETFL = 4
local O_NONBLOCK = 4
local function accept(fd)
  local _u24 = c.accept(fd, nil, nil)
  if _u24 < 0 then
    abort("accept")
  end
  c.fcntl(_u24, F_SETFL, O_NONBLOCK)
  return(_u24)
end
local function wait(fd, o)
  local x = threads[fd]
  local _u32
  if o == "out" then
    _u32 = POLLOUT
  else
    _u32 = POLLIN
  end
  local v = _u32
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
local BUFFER_SIZE = 1024
local function receive(fd)
  wait(fd)
  local b = ffi["new"]("char[?]", BUFFER_SIZE)
  local x = c.read(fd, b, BUFFER_SIZE)
  if x < 0 then
    return(abort())
  else
    if x > 0 then
      return(cstr(b))
    end
  end
end
local function send(fd, b)
  local i = 0
  local n = _35(b)
  local _u31 = ffi.cast("const char*", b)
  while i < n do
    wait(fd, "out")
    local x = c.write(fd, _u31 + i, n - i)
    if x < 0 then
      abort()
    end
    i = i + x
  end
end
return({active = active, enter = enter, listen = listen, send = send, wait = wait, start = start, receive = receive})
