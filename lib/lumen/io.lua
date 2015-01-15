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
