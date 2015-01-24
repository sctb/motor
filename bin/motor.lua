ffi = require("ffi")
cstr = ffi.string
setenv("define-c", {_stash = true, macro = function (x)
  return("|ffi.cdef[[" .. inner(x) .. "]]|")
end})
function dead63(c)
  return(coroutine.status(c) == "dead")
end
setenv("resume", {_stash = true, macro = function (...)
  local args = unstash({...})
  return(join({{"get", "coroutine", {"quote", "resume"}}}, args))
end})
setenv("yield", {_stash = true, macro = function (...)
  local args = unstash({...})
  return(join({{"get", "coroutine", {"quote", "yield"}}}, args))
end})
function thread(f)
  return(coroutine.create(f))
end
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
function active(fd)
  return(threads[fd].thread)
end
function enter(...)
  local _u9 = unstash({...})
  local fd = _u9.fd
  local thread = _u9.thread
  local state = _u9.state
  local final = _u9.final
  local x = {events = POLLNONE, fd = fd, thread = thread, state = state or fd, final = final or close}
  threads[fd] = x
end
local function leave(fd)
  local _u12 = threads[fd]
  local state = _u12.state
  local final = _u12.final
  final(state)
  threads[fd] = nil
end
local function run(fd)
  local _u14 = threads[fd]
  local x = _u14.state
  local t = _u14.thread
  local b,e = coroutine.resume(t, x)
  if not b then
    print("error:" .. " " .. string(e))
  end
  if dead63(t) then
    return(leave(fd))
  end
end
local function polls()
  local ps = {}
  local _u16 = threads
  local _u1 = nil
  for _u1 in next, _u16 do
    local x = _u16[_u1]
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
    local _u19 = a[i]
    local fd = _u19.fd
    local r = _u19.revents
    local _u20 = threads[fd]
    local v = _u20.events
    local t = _u20.thread
    if dead63(t) or error63(r) then
      leave(fd)
    else
      if v == POLLNONE or r > 0 then
        run(fd)
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
function loop()
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
  local _u25 = c.accept(fd, nil, nil)
  if _u25 < 0 then
    abort("accept")
  end
  c.fcntl(_u25, F_SETFL, O_NONBLOCK)
  return(_u25)
end
function listen(port, f)
  local function connect(fd)
    wait(fd, POLLIN)
    enter({_stash = true, fd = accept(fd), thread = thread(f)})
    return(connect(coroutine.yield()))
  end
  return(enter({_stash = true, fd = bind(port), thread = thread(connect)}))
end
function wait(fd, v)
  local x = threads[fd]
  x.events = v
  return(coroutine.yield())
end
local BUFFER_SIZE = 1024
function receive(fd)
  wait(fd, POLLIN)
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
function send(fd, b)
  local i = 0
  local n = _35(b)
  local _u31 = ffi.cast("const char*", b)
  while i < n do
    wait(fd, POLLOUT)
    local x = c.write(fd, _u31 + i, n - i)
    if x < 0 then
      abort()
    end
    i = i + x
  end
end
local function stream(fd)
  return({fd = fd, pos = 0, buffer = ""})
end
local function fill(s)
  local b = receive(s.fd)
  if b then
    s.buffer = s.buffer .. b
    return(true)
  end
end
local function before(s, pat)
  local i = nil
  while nil63(i) do
    local n = search(s.buffer, pat, s.pos)
    if nil63(n) then
      if not fill(s) then
        i = -1
      end
    else
      i = n
    end
  end
  if i >= 0 then
    local _u4 = s.pos
    s.pos = i
    return(clip(s.buffer, _u4, i))
  end
end
local function line(s, pat)
  local p = pat or "\n"
  local b = before(s, p)
  s.pos = s.pos + _35(p)
  return(b)
end
local function amount(s, n)
  while _35(s.buffer) - s.pos < n do
    if not fill(s) then
      break
    end
  end
  local b = clip(s.buffer, s.pos)
  s.pos = s.pos + _35(b)
  return(b)
end
function emit(s, b)
  return(send(s.fd, b))
end
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
function start(s)
  local _u6 = words(line(s, sep))
  local m = _u6[1]
  local p = _u6[2]
  local v = _u6[3]
  return({path = p, method = m, version = v})
end
function headers(s)
  local x = {}
  local b = line(s, sep2)
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
function body(s, n)
  return(amount(s, n))
end
local function response(data, code)
  return("HTTP/1.1 " .. code .. sep .. "Content-Length: " .. _35(data) .. sep2 .. data)
end
function respond(s, data)
  return(emit(s, response(data, "200 OK")))
end
function problem(s, data)
  return(emit(s, response(data, "500 Internal Server Error")))
end
function unknown(s)
  return(emit(s, response("Unknown", "404 Not Found")))
end
function serve(port, f)
  local function connect(fd)
    return(f(stream(fd)))
  end
  listen(port, connect)
  return(loop())
end
ffi.cdef[[
struct pg_conn;
struct pg_result;

typedef struct pg_conn PGconn;
typedef struct pg_result PGresult;

typedef enum
{
	CONNECTION_OK,
	CONNECTION_BAD,

	/* Non-blocking mode only below here */
	CONNECTION_STARTED,
	CONNECTION_MADE,
	CONNECTION_AWAITING_RESPONSE,
	CONNECTION_AUTH_OK,
	CONNECTION_SETENV,
	CONNECTION_SSL_STARTUP,
	CONNECTION_NEEDED
} ConnStatusType;

typedef enum
{
	PGRES_EMPTY_QUERY = 0,
	PGRES_COMMAND_OK,
	PGRES_TUPLES_OK,
	PGRES_COPY_OUT,
	PGRES_COPY_IN,
	PGRES_BAD_RESPONSE,
	PGRES_NONFATAL_ERROR,
	PGRES_FATAL_ERROR,
	PGRES_COPY_BOTH,
	PGRES_SINGLE_TUPLE
} ExecStatusType;

PGconn *PQconnectdb(const char *conninfo);

ConnStatusType PQstatus(const PGconn *conn);
ExecStatusType PQresultStatus(const PGresult *res);

void PQfinish(PGconn *conn);
void PQreset(PGconn *conn);

int PQsocket(const PGconn *conn);
int PQsendQuery(PGconn *conn, const char *command);
int PQconsumeInput(PGconn *conn);
int PQisBusy(PGconn *conn);
int PQsetnonblocking(PGconn *conn, int arg);
int PQflush(PGconn *conn);

char *PQerrorMessage(const PGconn *conn);
char *PQresultErrorMessage(const PGresult *res);

PGresult *PQgetResult(PGconn *conn);
void PQclear(PGresult *res);
char *PQcmdStatus(PGresult *res);
char *PQcmdTuples(PGresult *res);
int PQntuples(const PGresult *res);
int PQnfields(const PGresult *res);
char *PQfname(const PGresult *res, int column_number);
char *PQgetvalue(const PGresult *res, int row_number, int column_number);
]]
local pq = ffi.load("pq")
local function abort(p, name)
  local e = cstr(pq.PQerrorMessage(p))
  error((name or "error") .. ": " .. e)
end
local function connected63(p)
  return(pq.PQstatus(p) == pq.CONNECTION_OK)
end
local function finish(p)
  return(pq.PQfinish(p))
end
function connect(s, t)
  local p = pq.PQconnectdb(s)
  if connected63(p) then
    local x = pq.PQsetnonblocking(p, 1)
    if not (x == 0) then
      abort(p, "connect")
    end
    local fd = pq.PQsocket(p)
    enter({_stash = true, fd = fd, thread = t, state = p, final = finish})
    return(p)
  end
end
local function consume(p, fd)
  wait(fd, POLLIN)
  local x = pq.PQconsumeInput(p)
  if x == 0 then
    return(abort(p, "consume"))
  end
end
local function get_rows(res, n, m)
  local rs = {}
  local i = 0
  while i < n do
    local r = {}
    local j = 0
    while j < m do
      local k = cstr(pq.PQfname(res, j))
      local v = cstr(pq.PQgetvalue(res, i, j))
      r[k] = v
      j = j + 1
    end
    add(rs, r)
    i = i + 1
  end
  return(rs)
end
local function result(r)
  local x = pq.PQresultStatus(r)
  if x == pq.PGRES_COMMAND_OK then
    local a = cstr(pq.PQcmdTuples(r))
    local _u13
    if some63(a) then
      _u13 = number(a)
    end
    return({size = _u13, command = cstr(pq.PQcmdStatus(r))})
  else
    if x == pq.PGRES_TUPLES_OK or x == pq.PGRES_SINGLE_TUPLE then
      local n = pq.PQntuples(r)
      local m = pq.PQnfields(r)
      return({command = cstr(pq.PQcmdStatus(r)), rows = get_rows(r, n, m), size = n})
    else
      return({error = cstr(pq.PQresultErrorMessage(r))})
    end
  end
end
local function clear(r)
  return(pq.PQclear(r))
end
local function send_query(p, fd, q)
  local x = pq.PQsendQuery(p, q)
  if x == 0 then
    abort(p, "query")
  end
  local sent = false
  while not sent do
    wait(fd, POLLOUT)
    local _u10 = pq.PQflush(p)
    if _u10 < 0 then
      abort(p, "query")
    else
      if _u10 == 0 then
        sent = true
      end
    end
  end
end
local function get_results(p, fd)
  local rs = {}
  while true do
    if pq.PQisBusy(p) == 0 then
      local r = pq.PQgetResult(p)
      if is63(r) then
        add(rs, r)
      else
        break
      end
    else
      consume(p, fd)
    end
  end
  return(rs)
end
function query(p, q)
  local fd = pq.PQsocket(p)
  send_query(p, fd, q)
  local rs = get_results(p, fd)
  local xs = map(result, rs)
  map(clear, rs)
  return(xs)
end
