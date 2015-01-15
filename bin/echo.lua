environment = {{}}
target = "lua"
function nil63(x)
  return(x == nil)
end
function is63(x)
  return(not nil63(x))
end
function _35(x)
  return(#x)
end
function none63(x)
  return(_35(x) == 0)
end
function some63(x)
  return(_35(x) > 0)
end
function one63(x)
  return(_35(x) == 1)
end
function hd(l)
  return(l[1])
end
function string63(x)
  return(type(x) == "string")
end
function number63(x)
  return(type(x) == "number")
end
function boolean63(x)
  return(type(x) == "boolean")
end
function function63(x)
  return(type(x) == "function")
end
function obj63(x)
  return(is63(x) and type(x) == "table")
end
function atom63(x)
  return(nil63(x) or not obj63(x))
end
function nan63(n)
  return(not (n == n))
end
function inf63(n)
  return(n == 1 / 0 or n == -(1 / 0))
end
strlib = string
function clip(s, from, upto)
  return(strlib.sub(s, from + 1, upto))
end
function cut(x, from, upto)
  local l = {}
  local j = 0
  local _u126
  if nil63(from) or from < 0 then
    _u126 = 0
  else
    _u126 = from
  end
  local i = _u126
  local n = _35(x)
  local _u127
  if nil63(upto) or upto > n then
    _u127 = n
  else
    _u127 = upto
  end
  local _u24 = _u127
  while i < _u24 do
    l[j + 1] = x[i + 1]
    i = i + 1
    j = j + 1
  end
  local _u25 = x
  local k = nil
  for k in next, _u25 do
    local v = _u25[k]
    if not number63(k) then
      l[k] = v
    end
  end
  return(l)
end
function keys(x)
  local t = {}
  local _u28 = x
  local k = nil
  for k in next, _u28 do
    local v = _u28[k]
    if not number63(k) then
      t[k] = v
    end
  end
  return(t)
end
function edge(x)
  return(_35(x) - 1)
end
function inner(x)
  return(clip(x, 1, edge(x)))
end
function tl(l)
  return(cut(l, 1))
end
function char(s, n)
  return(clip(s, n, n + 1))
end
function code(s, n)
  local _u128
  if n then
    _u128 = n + 1
  end
  return(strlib.byte(s, _u128))
end
function string_literal63(x)
  return(string63(x) and char(x, 0) == "\"")
end
function id_literal63(x)
  return(string63(x) and char(x, 0) == "|")
end
function add(l, x)
  return(table.insert(l, x))
end
function drop(l)
  return(table.remove(l))
end
function last(l)
  return(l[edge(l) + 1])
end
function butlast(l)
  return(cut(l, 0, edge(l)))
end
function reverse(l)
  local l1 = keys(l)
  local i = edge(l)
  while i >= 0 do
    add(l1, l[i + 1])
    i = i - 1
  end
  return(l1)
end
function join(a, b)
  if a and b then
    local c = {}
    local o = _35(a)
    local _u43 = a
    local k = nil
    for k in next, _u43 do
      local v = _u43[k]
      c[k] = v
    end
    local _u45 = b
    local k = nil
    for k in next, _u45 do
      local v = _u45[k]
      if number63(k) then
        k = k + o
      end
      c[k] = v
    end
    return(c)
  else
    return(a or b or {})
  end
end
function reduce(f, x)
  if none63(x) then
    return(x)
  else
    if one63(x) then
      return(hd(x))
    else
      return(f(hd(x), reduce(f, tl(x))))
    end
  end
end
function find(f, t)
  local _u49 = t
  local _u1 = nil
  for _u1 in next, _u49 do
    local x = _u49[_u1]
    local _u51 = f(x)
    if _u51 then
      return(_u51)
    end
  end
end
function first(f, l)
  local i = 0
  local n = _35(l)
  while i < n do
    local x = f(l[i + 1])
    if x then
      return(x)
    end
    i = i + 1
  end
end
function in63(x, t)
  return(find(function (y)
    return(x == y)
  end, t))
end
function pair(l)
  local i = 0
  local l1 = {}
  while i < _35(l) do
    add(l1, {l[i + 1], l[i + 1 + 1]})
    i = i + 2
  end
  return(l1)
end
function sort(l, f)
  table.sort(l, f)
  return(l)
end
function iterate(f, count)
  local i = 0
  while i < count do
    f(i)
    i = i + 1
  end
end
function replicate(n, x)
  local l = {}
  iterate(function ()
    return(add(l, x))
  end, n)
  return(l)
end
function step(f, l)
  return(iterate(function (i)
    return(f(l[i + 1]))
  end, _35(l)))
end
function map(f, x)
  local t = {}
  local i = 0
  local n = _35(x)
  while i < n do
    local y = f(x[i + 1])
    if is63(y) then
      add(t, y)
    end
    i = i + 1
  end
  local _u64 = x
  local k = nil
  for k in next, _u64 do
    local v = _u64[k]
    if not number63(k) then
      local y = f(v)
      if is63(y) then
        t[k] = y
      end
    end
  end
  return(t)
end
function keep(f, x)
  return(map(function (v)
    if f(v) then
      return(v)
    end
  end, x))
end
function keys63(t)
  local _u69 = t
  local k = nil
  for k in next, _u69 do
    local _u2 = _u69[k]
    if not number63(k) then
      return(true)
    end
  end
  return(false)
end
function empty63(t)
  local _u72 = t
  local _u3 = nil
  for _u3 in next, _u72 do
    local _u4 = _u72[_u3]
    return(false)
  end
  return(true)
end
function stash(args)
  if keys63(args) then
    local p = {}
    local _u75 = args
    local k = nil
    for k in next, _u75 do
      local v = _u75[k]
      if not number63(k) then
        p[k] = v
      end
    end
    p._stash = true
    add(args, p)
  end
  return(args)
end
function unstash(args)
  if none63(args) then
    return({})
  else
    local l = last(args)
    if obj63(l) and l._stash then
      local args1 = butlast(args)
      local _u78 = l
      local k = nil
      for k in next, _u78 do
        local v = _u78[k]
        if not (k == "_stash") then
          args1[k] = v
        end
      end
      return(args1)
    else
      return(args)
    end
  end
end
function search(s, pattern, start)
  local _u129
  if start then
    _u129 = start + 1
  end
  local _u81 = _u129
  local i = strlib.find(s, pattern, _u81, true)
  return(i and i - 1)
end
function split(s, sep)
  if s == "" or sep == "" then
    return({})
  else
    local l = {}
    while true do
      local i = search(s, sep)
      if nil63(i) then
        break
      else
        add(l, clip(s, 0, i))
        s = clip(s, i + 1)
      end
    end
    add(l, s)
    return(l)
  end
end
function cat(...)
  local xs = unstash({...})
  if none63(xs) then
    return("")
  else
    return(reduce(function (a, b)
      return(a .. b)
    end, xs))
  end
end
function _43(...)
  local xs = unstash({...})
  return(reduce(function (a, b)
    return(a + b)
  end, xs))
end
function _(...)
  local xs = unstash({...})
  return(reduce(function (b, a)
    return(a - b)
  end, reverse(xs)))
end
function _42(...)
  local xs = unstash({...})
  return(reduce(function (a, b)
    return(a * b)
  end, xs))
end
function _47(...)
  local xs = unstash({...})
  return(reduce(function (b, a)
    return(a / b)
  end, reverse(xs)))
end
function _37(...)
  local xs = unstash({...})
  return(reduce(function (b, a)
    return(a % b)
  end, reverse(xs)))
end
function _62(a, b)
  return(a > b)
end
function _60(a, b)
  return(a < b)
end
function _61(a, b)
  return(a == b)
end
function _6261(a, b)
  return(a >= b)
end
function _6061(a, b)
  return(a <= b)
end
function number(s)
  return(tonumber(s))
end
function number_code63(n)
  return(n > 47 and n < 58)
end
function numeric63(s)
  local i = 0
  local n = _35(s)
  while i < n do
    if not number_code63(code(s, i)) then
      return(false)
    end
    i = i + 1
  end
  return(true)
end
function string(x, depth)
  if depth and depth > 7 then
    return("#<circular>")
  else
    if nil63(x) then
      return("nil")
    else
      if nan63(x) then
        return("#nan")
      else
        if x == 1 / 0 then
          return("#+inf")
        else
          if x == -(1 / 0) then
            return("#-inf")
          else
            if boolean63(x) then
              if x then
                return("#t")
              else
                return("#f")
              end
            else
              if function63(x) then
                return("#<function>")
              else
                if atom63(x) then
                  return(x .. "")
                else
                  local s = "("
                  local sp = ""
                  local xs = {}
                  local ks = {}
                  local d = (depth or 0) + 1
                  local _u104 = x
                  local k = nil
                  for k in next, _u104 do
                    local v = _u104[k]
                    if number63(k) then
                      xs[k] = string(v, d)
                    else
                      add(ks, k .. ":")
                      add(ks, string(v, d))
                    end
                  end
                  local _u106 = join(xs, ks)
                  local _u5 = nil
                  for _u5 in next, _u106 do
                    local v = _u106[_u5]
                    s = s .. sp .. v
                    sp = " "
                  end
                  return(s .. ")")
                end
              end
            end
          end
        end
      end
    end
  end
end
local function produces_string63(x)
  return(string_literal63(x) or obj63(x) and (hd(x) == "cat" or hd(x) == "string"))
end
function space(xs)
  local string = function (x)
    if produces_string63(x) then
      return(x)
    else
      return({"string", x})
    end
  end
  if one63(xs) then
    return(string(hd(xs)))
  else
    return(reduce(function (a, b)
      return({"cat", string(a), "\" \"", string(b)})
    end, xs))
  end
end
function apply(f, args)
  local _u115 = stash(args)
  return(f(unpack(_u115)))
end
local _u116 = 0
function unique()
  _u116 = _u116 + 1
  return("_u" .. _u116)
end
function unique63(id)
  return("_u" == clip(id, 0, 2))
end
function _37message_handler(msg)
  local i = search(msg, ": ")
  return(clip(msg, i + 2))
end
function toplevel63()
  return(one63(environment))
end
function setenv(k, ...)
  local _u121 = unstash({...})
  local keys = cut(_u121, 0)
  if string63(k) then
    local _u130
    if keys.toplevel then
      _u130 = hd(environment)
    else
      _u130 = last(environment)
    end
    local frame = _u130
    local entry = frame[k] or {}
    local _u123 = keys
    local _u125 = nil
    for _u125 in next, _u123 do
      local v = _u123[_u125]
      entry[_u125] = v
    end
    frame[k] = entry
  end
end
function read_file(path)
  local f = io.open(path)
  return(f.read(f, "*a"))
end
function write_file(path, data)
  local f = io.open(path, "w")
  return(f.write(f, data))
end
function write(x)
  return(io.write(x))
end
function exit(code)
  return(os.exit(code))
end
function argv()
  return(arg)
end
ffi = require("ffi")
setenv("define-c", {_stash = true, macro = function (x)
  return("|ffi.cdef[[" .. inner(x) .. "]]|")
end})
print(string("hi"))
