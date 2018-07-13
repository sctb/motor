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
local pq = ffi["load"]("pq")
local cstr = ffi.string
local function abort(p, name)
  local __e = cstr(pq.PQerrorMessage(p))
  error((name or "error") .. ": " .. __e)
end
local function connected63(p)
  return pq.PQstatus(p) == pq.CONNECTION_OK
end
local function finish(p)
  return pq.PQfinish(p)
end
local function connect(s, t)
  local __p = pq.PQconnectdb(s)
  if connected63(__p) then
    local __x = pq.PQsetnonblocking(__p, 1)
    if not( __x == 0) then
      abort(__p, "connect")
    end
    if function63(t) then
      local __f = t
      t = coroutine.create(function ()
        return __f(__p)
      end)
    end
    local __fd = pq.PQsocket(__p)
    local __f1 = function ()
      return finish(__p)
    end
    motor.enter(__fd, t, __f1)
    return __p
  end
end
local function consume(p, fd)
  motor.wait(fd)
  local __x1 = pq.PQconsumeInput(p)
  if __x1 == 0 then
    return abort(p, "consume")
  end
end
local function getRows(res, n, m)
  local __rs = {}
  local __i = 0
  while __i < n do
    local __r8 = {}
    local __j = 0
    while __j < m do
      local __k = cstr(pq.PQfname(res, __j))
      local __v = cstr(pq.PQgetvalue(res, __i, __j))
      __r8[__k] = __v
      __j = __j + 1
    end
    add(__rs, __r8)
    __i = __i + 1
  end
  return __rs
end
local function result(r)
  local __x2 = pq.PQresultStatus(r)
  if __x2 == pq.PGRES_COMMAND_OK then
    local __a = cstr(pq.PQcmdTuples(r))
    local ____x3 = {}
    local __e1
    if some63(__a) then
      __e1 = number(__a)
    end
    ____x3.size = __e1
    ____x3.command = cstr(pq.PQcmdStatus(r))
    return ____x3
  else
    if __x2 == pq.PGRES_TUPLES_OK or __x2 == pq.PGRES_SINGLE_TUPLE then
      local __n = pq.PQntuples(r)
      local __m = pq.PQnfields(r)
      local ____x4 = {}
      ____x4.command = cstr(pq.PQcmdStatus(r))
      ____x4.rows = getRows(r, __n, __m)
      ____x4.size = __n
      return ____x4
    else
      local ____x5 = {}
      ____x5.error = cstr(pq.PQresultErrorMessage(r))
      return ____x5
    end
  end
end
local function clear(r)
  return pq.PQclear(r)
end
local function sendQuery(p, fd, q)
  local __x6 = pq.PQsendQuery(p, q)
  if __x6 == 0 then
    abort(p, "query")
  end
  local __sent = false
  while not __sent do
    motor.wait(fd, "out")
    local __x7 = pq.PQflush(p)
    if __x7 < 0 then
      abort(p, "query")
    else
      if __x7 == 0 then
        __sent = true
      end
    end
  end
end
local function getResults(p, fd)
  local __rs1 = {}
  while true do
    if pq.PQisBusy(p) == 0 then
      local __r13 = pq.PQgetResult(p)
      if is63(__r13) then
        add(__rs1, __r13)
      else
        break
      end
    else
      consume(p, fd)
    end
  end
  return __rs1
end
local function query(p, q)
  local __fd1 = pq.PQsocket(p)
  sendQuery(p, __fd1, q)
  local __rs2 = getResults(p, __fd1)
  local __xs = map(result, __rs2)
  map(clear, __rs2)
  return __xs
end
return {query = query, connect = connect}
