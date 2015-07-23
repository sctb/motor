local ffi = require("ffi")
local motor = require("motor")
local pq = ffi46load("pq")
local cstr = ffi46string
local function abort(p, name)
  local e = cstr(pq46PQerrorMessage(p))
  error((name or "error") .. ": " .. e)
end
local function connected63(p)
  return(pq46PQstatus(p) == pq46CONNECTION_OK)
end
local function finish(p)
  return(pq46PQfinish(p))
end
local function connect(s, t)
  local p = pq46PQconnectdb(s)
  if connected63(p) then
    local x = pq46PQsetnonblocking(p, 1)
    if not (x == 0) then
      abort(p, "connect")
    end
    if function63(t) then
      local f = t
      t = coroutine46create(function ()
        return(f(p))
      end)
    end
    local fd = pq46PQsocket(p)
    local _f = function ()
      return(finish(p))
    end
    motor46enter(fd, t, _f)
    return(p)
  end
end
local function consume(p, fd)
  motor46wait(fd)
  local x = pq46PQconsumeInput(p)
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
      local k = cstr(pq46PQfname(res, j))
      local v = cstr(pq46PQgetvalue(res, i, j))
      r[k] = v
      j = j + 1
    end
    add(rs, r)
    i = i + 1
  end
  return(rs)
end
local function result(r)
  local x = pq46PQresultStatus(r)
  if x == pq46PGRES_COMMAND_OK then
    local a = cstr(pq46PQcmdTuples(r))
    local _x = {}
    local _e
    if some63(a) then
      _e = number(a)
    end
    _x.size = _e
    _x.command = cstr(pq46PQcmdStatus(r))
    return(_x)
  else
    if x == pq46PGRES_TUPLES_OK or x == pq46PGRES_SINGLE_TUPLE then
      local n = pq46PQntuples(r)
      local m = pq46PQnfields(r)
      local _x1 = {}
      _x1.command = cstr(pq46PQcmdStatus(r))
      _x1.rows = get_rows(r, n, m)
      _x1.size = n
      return(_x1)
    else
      local _x2 = {}
      _x2.error = cstr(pq46PQresultErrorMessage(r))
      return(_x2)
    end
  end
end
local function clear(r)
  return(pq46PQclear(r))
end
local function send_query(p, fd, q)
  local x = pq46PQsendQuery(p, q)
  if x == 0 then
    abort(p, "query")
  end
  local sent = false
  while not sent do
    motor46wait(fd, "out")
    local _x3 = pq46PQflush(p)
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
    if pq46PQisBusy(p) == 0 then
      local r = pq46PQgetResult(p)
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
  local fd = pq46PQsocket(p)
  send_query(p, fd, q)
  local rs = get_results(p, fd)
  local xs = map(result, rs)
  map(clear, rs)
  return(xs)
end
return({query = query, connect = connect})
