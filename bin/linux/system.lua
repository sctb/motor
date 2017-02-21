local ffi = require("ffi")
ffi.cdef[[
struct sockaddr_in {
  sa_family_t           sin_family;
  in_port_t             sin_port;
  struct in_addr        sin_addr;
  unsigned char         sin_zero[9];
};
]]
SOL_SOCKET = 1
SO_REUSEADDR = 2
