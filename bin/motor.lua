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
local function abort(name)
  local __e = ffi.string(ffi.C.strerror(ffi.errno()))
  error((name or "error") .. ": " .. __e)
end
local AF_INET = 2
local SOCK_STREAM = 1
local IPPROTO_TCP = 6
local INADDR_ANY = 0
local function socket()
  local __fd = ffi.C.socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
  if __fd < 0 then
    abort("socket")
  end
  local __a = ffi["new"]("int[1]", 1)
  local __n = ffi.sizeof("int")
  local __x = ffi.C.setsockopt(__fd, SOL_SOCKET, SO_REUSEADDR, __a, __n)
  if __x < 0 then
    abort("setsockopt")
  end
  return __fd
end
local function bind(port)
  local __fd1 = socket()
  local __p = ffi["new"]("struct sockaddr_in[1]")
  local __n1 = ffi.sizeof("struct sockaddr_in")
  local __a1 = __p[0]
  __a1.sin_family = AF_INET
  __a1.sin_port = ffi.C.htons(port)
  __a1.sin_addr.s_addr = ffi.C.htonl(INADDR_ANY)
  local __p1 = ffi.cast("struct sockaddr*", __p)
  local __x1 = ffi.C.bind(__fd1, __p1, __n1)
  if __x1 < 0 then
    abort("bind")
  end
  local __x2 = ffi.C.listen(__fd1, 10)
  if __x2 < 0 then
    abort("listen")
  end
  return __fd1
end
local POLLNONE = 0
local POLLIN = 1
local POLLOUT = 4
local POLLERR = 8
local POLLHUP = 16
local POLLNVAL = 32
local threads = {}
local function error63(v)
  return v > 7
end
local function close(fd)
  if ffi.C.close(fd) < 0 then
    return abort("close")
  end
end
local function active(fd)
  return threads[fd].thread
end
local function enter(fd, thread, final)
  local __f = final or function ()
    return close(fd)
  end
  local ____x4 = {}
  ____x4.fd = fd
  ____x4.thread = thread
  ____x4.events = POLLNONE
  ____x4.final = __f
  local __x3 = ____x4
  threads[fd] = __x3
  return threads[fd]
end
local function leave(fd)
  local __x5 = threads[fd]
  __x5.final()
  threads[fd] = nil
  return threads[fd]
end
local function cleanup()
  local ____o = threads
  local __fd2 = nil
  for __fd2 in next, ____o do
    local __x6 = ____o[__fd2]
    leave(__fd2)
  end
end
local function dead63(c)
  return coroutine.status(c) == "dead"
end
local function run(t, fd)
  local b,e = coroutine.resume(t)
  if not b then
    print("error:" .. e)
  end
  if dead63(t) then
    return leave(fd)
  end
end
local function polls()
  local __ps = {}
  local ____o1 = threads
  local ____i1 = nil
  for ____i1 in next, ____o1 do
    local __x7 = ____o1[____i1]
    local __p2 = ffi["new"]("struct pollfd")
    __p2.fd = __x7.fd
    __p2.events = __x7.events
    add(__ps, __p2)
  end
  return __ps
end
local function tick(a, n)
  local __i2 = 0
  while __i2 < n do
    local ____id = a[__i2]
    local __fd3 = ____id.fd
    local __r14 = ____id.revents
    local ____id1 = threads[__fd3]
    local __v = ____id1.events
    local __t = ____id1.thread
    if dead63(__t) or error63(__r14) then
      leave(__fd3)
    else
      if __v == POLLNONE or __r14 > 0 then
        run(__t, __fd3)
      end
    end
    __i2 = __i2 + 1
  end
end
local IMMEDIATE = 0
local NEVER = -1
local function timeout()
  if find(function (x)
    return x.events == POLLNONE
  end, threads) then
    return IMMEDIATE
  else
    return NEVER
  end
end
local function loop()
  while not empty63(threads) do
    local __p3 = polls()
    local __n4 = _35(__p3)
    local __a2 = ffi["new"]("struct pollfd[?]", __n4, __p3)
    local __t1 = timeout(__p3)
    ffi.C.poll(__a2, __n4, __t1)
    tick(__a2, __n4)
  end
end
local function start()
  local ____id2 = {xpcall(function ()
    return loop()
  end, function (m)
    if obj63(m) then
      return m
    else
      local __e2
      if string63(m) then
        __e2 = clip(m, search(m, ": ") + 2)
      else
        local __e3
        if nil63(m) then
          __e3 = ""
        else
          __e3 = str(m)
        end
        __e2 = __e3
      end
      return {stack = debug.traceback(), message = __e2}
    end
  end)}
  local __x9 = ____id2[1]
  local __e1 = ____id2[2]
  if __e1 then
    print("error: " .. __e1)
  end
  return cleanup()
end
local F_SETFL = 4
local O_NONBLOCK = 4
local function accept(fd)
  local __fd4 = ffi.C.accept(fd, nil, nil)
  if __fd4 < 0 then
    abort("accept")
  end
  ffi.C.fcntl(__fd4, F_SETFL, O_NONBLOCK)
  return __fd4
end
local function wait(fd, o)
  local __x10 = threads[fd]
  local __e4
  if o == "out" then
    __e4 = POLLOUT
  else
    __e4 = POLLIN
  end
  local __v1 = __e4
  __x10.events = __v1
  return coroutine.yield()
end
local function listen(port, f)
  local __fd5 = bind(port)
  local function connect()
    wait(__fd5)
    local __fd6 = accept(__fd5)
    local __f1 = function ()
      return f(__fd6)
    end
    enter(__fd6, coroutine.create(__f1))
    return connect(coroutine.yield())
  end
  return enter(__fd5, coroutine.create(connect))
end
local function read(fd, b)
  wait(fd)
  local __n5 = buffer.space(b)
  if __n5 > 0 then
    local __p4 = buffer.pointer(b)
    local __x11 = ffi.C.read(fd, __p4, __n5)
    if __x11 < 0 then
      abort("read")
    end
    b.length = b.length + __x11
    return __x11
  end
end
local function receive(fd)
  local __b = buffer.create()
  local __n6 = read(fd, __b)
  if __n6 > 0 then
    return buffer.string(__b)
  end
end
local function write(fd, p, n)
  wait(fd, "out")
  local __x12 = ffi.C.write(fd, p, n)
  if __x12 < 0 then
    abort("send")
  end
  return __x12
end
local function send(fd, s)
  local __i3 = 0
  local __n7 = _35(s)
  local __b1 = ffi.cast("const char*", s)
  while __i3 < __n7 do
    local __x13 = write(fd, __b1 + __i3, __n7 - __i3)
    __i3 = __i3 + __x13
  end
end
return {enter = enter, write = write, send = send, read = read, active = active, listen = listen, wait = wait, start = start, receive = receive}
