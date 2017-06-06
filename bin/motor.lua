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
  local _e = cstr(c.strerror(ffi.errno()))
  error((name or "error") .. ": " .. _e)
end
local AF_INET = 2
local SOCK_STREAM = 1
local IPPROTO_TCP = 6
local INADDR_ANY = 0
local function socket()
  local _fd = c.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if _fd < 0 then
    abort("socket")
  end
  local _a = ffi["new"]("int[1]", 1)
  local _n = ffi.sizeof("int")
  local _x = c.setsockopt(_fd, SOL_SOCKET, SO_REUSEADDR, _a, _n)
  if _x < 0 then
    abort("setsockopt")
  end
  return(_fd)
end
local function bind(port)
  local _fd1 = socket()
  local _p = ffi["new"]("struct sockaddr_in[1]")
  local _n1 = ffi.sizeof("struct sockaddr_in")
  local _a1 = _p[0]
  _a1.sin_family = AF_INET
  _a1.sin_port = c.htons(port)
  _a1.sin_addr.s_addr = c.htonl(INADDR_ANY)
  local _p1 = ffi.cast("struct sockaddr*", _p)
  local _x1 = c.bind(_fd1, _p1, _n1)
  if _x1 < 0 then
    abort("bind")
  end
  local _x2 = c.listen(_fd1, 10)
  if _x2 < 0 then
    abort("listen")
  end
  return(_fd1)
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
  local _f = final or function ()
    return(close(fd))
  end
  local __x4 = {}
  __x4.fd = fd
  __x4.thread = thread
  __x4.final = _f
  __x4.events = POLLNONE
  local _x3 = __x4
  threads[fd] = _x3
  return(threads[fd])
end
local function leave(fd)
  local _x5 = threads[fd]
  _x5.final()
  threads[fd] = nil
  return(threads[fd])
end
local function cleanup()
  local __o = threads
  local _fd2 = nil
  for _fd2 in next, __o do
    local _x6 = __o[_fd2]
    leave(_fd2)
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
  local _ps = {}
  local __o1 = threads
  local __i1 = nil
  for __i1 in next, __o1 do
    local _x7 = __o1[__i1]
    local _p2 = ffi["new"]("struct pollfd")
    _p2.fd = _x7.fd
    _p2.events = _x7.events
    add(_ps, _p2)
  end
  return(_ps)
end
local function tick(a, n)
  local _i2 = 0
  while _i2 < n do
    local __id = a[_i2]
    local _fd3 = __id.fd
    local _r14 = __id.revents
    local __id1 = threads[_fd3]
    local _t = __id1.thread
    local _v = __id1.events
    if dead63(_t) or error63(_r14) then
      leave(_fd3)
    else
      if _v == POLLNONE or _r14 > 0 then
        run(_t, _fd3)
      end
    end
    _i2 = _i2 + 1
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
    local _p3 = polls()
    local _n4 = _35(_p3)
    local _a2 = ffi["new"]("struct pollfd[?]", _n4, _p3)
    local _t1 = timeout(_p3)
    c.poll(_a2, _n4, _t1)
    tick(_a2, _n4)
  end
end
local function start()
  local __x8 = nil
  local __msg = nil
  local __trace = nil
  local _e2
  if xpcall(function ()
    __x8 = loop()
    return(__x8)
  end, function (m)
    __trace = debug.traceback()
    local _e3
    if string63(m) then
      _e3 = clip(m, search(m, ": ") + 2)
    else
      local _e4
      if nil63(m) then
        _e4 = ""
      else
        _e4 = str(m)
      end
      _e3 = _e4
    end
    __msg = _e3
    return(__msg)
  end) then
    _e2 = {true, __x8}
  else
    _e2 = {false, {message = __msg, stack = __trace}}
  end
  local __id2 = _e2
  local _x11 = __id2[1]
  local _e1 = __id2[2]
  if _e1 then
    print("error: " .. _e1)
  end
  return(cleanup())
end
local F_SETFL = 4
local O_NONBLOCK = 4
local function accept(fd)
  local _fd4 = c.accept(fd, nil, nil)
  if _fd4 < 0 then
    abort("accept")
  end
  c.fcntl(_fd4, F_SETFL, O_NONBLOCK)
  return(_fd4)
end
local function wait(fd, o)
  local _x12 = threads[fd]
  local _e5
  if o == "out" then
    _e5 = POLLOUT
  else
    _e5 = POLLIN
  end
  local _v1 = _e5
  _x12.events = _v1
  return(coroutine.yield())
end
local function listen(port, f)
  local _fd5 = bind(port)
  local function connect()
    wait(_fd5)
    local _fd6 = accept(_fd5)
    local _f1 = function ()
      return(f(_fd6))
    end
    enter(_fd6, coroutine.create(_f1))
    return(connect(coroutine.yield()))
  end
  return(enter(_fd5, coroutine.create(connect)))
end
local function read(fd, b)
  wait(fd)
  local _n5 = buffer.space(b)
  if _n5 > 0 then
    local _p4 = buffer.pointer(b)
    local _x13 = c.read(fd, _p4, _n5)
    if _x13 < 0 then
      abort("read")
    end
    b.length = b.length + _x13
    return(_x13)
  end
end
local function receive(fd)
  local _b = buffer.create()
  local _n6 = read(fd, _b)
  if _n6 > 0 then
    return(buffer.string(_b))
  end
end
local function write(fd, p, n)
  wait(fd, "out")
  local _x14 = c.write(fd, p, n)
  if _x14 < 0 then
    abort("send")
  end
  return(_x14)
end
local function send(fd, s)
  local _i3 = 0
  local _n7 = _35(s)
  local _b1 = ffi.cast("const char*", s)
  while _i3 < _n7 do
    local _x15 = write(fd, _b1 + _i3, _n7 - _i3)
    _i3 = _i3 + _x15
  end
end
return({active = active, enter = enter, wait = wait, listen = listen, read = read, receive = receive, write = write, send = send, start = start})
