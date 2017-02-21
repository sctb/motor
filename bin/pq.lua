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
  local e = cstr(pq.PQerrorMessage(p))
  error((name or "error") .. ": " .. e)
end
local function connected63(p)
  return(pq.PQstatus(p) == pq.CONNECTION_OK)
end
local function finish(p)
  return(pq.PQfinish(p))
end
local function connect(s, t)
  local p = pq.PQconnectdb(s)
  if connected63(p) then
    local x = pq.PQsetnonblocking(p, 1)
    if not( x == 0) then
      abort(p, "connect")
    end
    if function63(t) then
      local f = t
      t = coroutine.create(function ()
        return(f(p))
      end)
    end
    local fd = pq.PQsocket(p)
    local _f = function ()
      return(finish(p))
    end
    motor.enter(fd, t, _f)
    return(p)
  end
end
local function consume(p, fd)
  motor.wait(fd)
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
    local _x = {}
    local _e
    if some63(a) then
      _e = number(a)
    end
    _x.size = _e
    _x.command = cstr(pq.PQcmdStatus(r))
    return(_x)
  else
    if x == pq.PGRES_TUPLES_OK or x == pq.PGRES_SINGLE_TUPLE then
      local n = pq.PQntuples(r)
      local m = pq.PQnfields(r)
      local _x1 = {}
      _x1.command = cstr(pq.PQcmdStatus(r))
      _x1.rows = get_rows(r, n, m)
      _x1.size = n
      return(_x1)
    else
      local _x2 = {}
      _x2.error = cstr(pq.PQresultErrorMessage(r))
      return(_x2)
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
    motor.wait(fd, "out")
    local _x3 = pq.PQflush(p)
    if _x3 < 0 then
      abort(p, "query")
    else
      if _x3 == 0 then
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
local function query(p, q)
  local fd = pq.PQsocket(p)
  send_query(p, fd, q)
  local rs = get_results(p, fd)
  local xs = map(result, rs)
  map(clear, rs)
  return(xs)
end
return({query = query, connect = connect})
