local ffi = require("ffi")
local motor = require("motor")
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
local cstr = ffi.string
local function abort(p, name)
  local _e = cstr(pq.PQerrorMessage(p))
  error((name or "error") .. ": " .. _e)
end
local function connected63(p)
  return(pq.PQstatus(p) == pq.CONNECTION_OK)
end
local function finish(p)
  return(pq.PQfinish(p))
end
local function connect(s, t)
  local _p = pq.PQconnectdb(s)
  if connected63(_p) then
    local _x = pq.PQsetnonblocking(_p, 1)
    if not( _x == 0) then
      abort(_p, "connect")
    end
    if function63(t) then
      local _f = t
      t = coroutine.create(function ()
        return(_f(_p))
      end)
    end
    local _fd = pq.PQsocket(_p)
    local _f1 = function ()
      return(finish(_p))
    end
    motor.enter(_fd, t, _f1)
    return(_p)
  end
end
local function consume(p, fd)
  motor.wait(fd)
  local _x1 = pq.PQconsumeInput(p)
  if _x1 == 0 then
    return(abort(p, "consume"))
  end
end
local function get_rows(res, n, m)
  local _rs = {}
  local _i = 0
  while _i < n do
    local _r8 = {}
    local _j = 0
    while _j < m do
      local _k = cstr(pq.PQfname(res, _j))
      local _v = cstr(pq.PQgetvalue(res, _i, _j))
      _r8[_k] = _v
      _j = _j + 1
    end
    add(_rs, _r8)
    _i = _i + 1
  end
  return(_rs)
end
local function result(r)
  local _x2 = pq.PQresultStatus(r)
  if _x2 == pq.PGRES_COMMAND_OK then
    local _a = cstr(pq.PQcmdTuples(r))
    local __x3 = {}
    __x3.command = cstr(pq.PQcmdStatus(r))
    local _e1
    if some63(_a) then
      _e1 = number(_a)
    end
    __x3.size = _e1
    return(__x3)
  else
    if _x2 == pq.PGRES_TUPLES_OK or _x2 == pq.PGRES_SINGLE_TUPLE then
      local _n = pq.PQntuples(r)
      local _m = pq.PQnfields(r)
      local __x4 = {}
      __x4.command = cstr(pq.PQcmdStatus(r))
      __x4.size = _n
      __x4.rows = get_rows(r, _n, _m)
      return(__x4)
    else
      local __x5 = {}
      __x5.error = cstr(pq.PQresultErrorMessage(r))
      return(__x5)
    end
  end
end
local function clear(r)
  return(pq.PQclear(r))
end
local function send_query(p, fd, q)
  local _x6 = pq.PQsendQuery(p, q)
  if _x6 == 0 then
    abort(p, "query")
  end
  local _sent = false
  while not _sent do
    motor.wait(fd, "out")
    local _x7 = pq.PQflush(p)
    if _x7 < 0 then
      abort(p, "query")
    else
      if _x7 == 0 then
        _sent = true
      end
    end
  end
end
local function get_results(p, fd)
  local _rs1 = {}
  while true do
    if pq.PQisBusy(p) == 0 then
      local _r13 = pq.PQgetResult(p)
      if is63(_r13) then
        add(_rs1, _r13)
      else
        break
      end
    else
      consume(p, fd)
    end
  end
  return(_rs1)
end
local function query(p, q)
  local _fd1 = pq.PQsocket(p)
  send_query(p, _fd1, q)
  local _rs2 = get_results(p, _fd1)
  local _xs = map(result, _rs2)
  map(clear, _rs2)
  return(_xs)
end
return({connect = connect, query = query})
