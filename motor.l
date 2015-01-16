;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define-macro define-c (x)
  (cat "|ffi.cdef[[" (inner x) "]]|"))

(define-c |
int socket(int domain, int type, int protocol);

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
|)

(define abort (name)
  (let (e (ffi.string (ffi.C.strerror (ffi.errno))))
    (error (cat (or name 'error) ": " e))))

(define PF_INET 2)
(define AF_INET 2)
(define INADDR_ANY 0)
(define SOCK_STREAM 1)
(define IPPROTO_TCP 6)

(define socket ()
  (let (fd (ffi.C.socket PF_INET SOCK_STREAM IPPROTO_TCP))
    (when (< fd 0)
      (abort 'socket))
    fd))

(define close (fd)
  (when (< (ffi.C.close fd) 0)
    (abort 'close)))

(define listen (port)
  (let (s (socket)
        p (ffi.new "struct sockaddr_in[1]")
        n (ffi.sizeof "struct sockaddr_in")
        a (get p 0))
    (set a.sin_family AF_INET)
    (set a.sin_port (ffi.C.htons port))
    (set a.sin_addr.s_addr INADDR_ANY)
    (let (p (ffi.cast "struct sockaddr*" p)
          x (ffi.C.bind s p n))
      (when (< x 0)
        (abort 'bind)))
    (let (x (ffi.C.listen s 10))
      (when (< x 0)
        (abort 'listen)))
    s))

(define accept (fd)
  (let (s (ffi.C.accept fd nil nil))
    (when (< s 0)
      (abort 'accept))
    s))

(define POLLIN          0x0001)
(define POLLOUT         0x0004)
(define POLLERR         0x0008)
(define POLLHUP         0x0010)
(define POLLNVAL        0x0020)

(define threads (obj))
(define polls ())

(define error? (r)
  (> r 0x0007))

(define enter (f fd rest: vs)
  (let (p (list fd (apply bit.bor vs)))
    (add polls p)
    (set (get threads fd) (thread f))))

(define leave (fd)
  (set polls (keep (fn ((fd1)) (not (= fd fd1))) polls))
  (set (get threads fd) nil)
  (close fd))

(define poll ((fd ev))
  (let (p (ffi.new "struct pollfd"))
    (set p.fd fd)
    (set p.events ev)
    p))

(define loop ()
  (while #t
    (let (n (# polls))
      (when (> n 0)
        (let (s (map poll polls)
              a (ffi.new "struct pollfd[?]" n s))
          (ffi.C.poll a n -1)
          (let (i 0)
            (while (< i n)
              (let ((:fd revents: r) (get a i))
                (when (> r 0)
                  (if (error? r) (leave fd)
                    (let (c (get threads fd)
                          |f,e| (resume c fd r))
                      (unless f
                        (pr "error:" e))
                      (when (or (not f) (dead? c))
                        (leave fd))))))
              (inc i))))))))
