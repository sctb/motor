;; -*- mode: lisp -*-

(define ffi (require 'ffi))
(define c ffi.C)

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

typedef unsigned int size_t;
typedef int ssize_t;

ssize_t read(int fildes, void *buf, size_t nbyte);
ssize_t write(int fildes, const void *buf, size_t nbyte);
|)

(define abort (name)
  (let (e (ffi.string (c.strerror (ffi.errno))))
    (error (cat (or name 'error) ": " e))))

(define PF_INET 2)
(define AF_INET 2)
(define INADDR_ANY 0)
(define SOCK_STREAM 1)
(define IPPROTO_TCP 6)

(define socket ()
  (let (s (c.socket PF_INET SOCK_STREAM IPPROTO_TCP))
    (when (< s 0)
      (abort 'socket))
    s))

(define close (s)
  (when (< (c.close s) 0)
    (abort 'close)))

(define listen (port)
  (let (s (socket)
        p (ffi.new "struct sockaddr_in[1]")
        n (ffi.sizeof "struct sockaddr_in")
        a (get p 0))
    (set a.sin_family AF_INET)
    (set a.sin_port (c.htons port))
    (set a.sin_addr.s_addr INADDR_ANY)
    (let (p (ffi.cast "struct sockaddr*" p)
          x (c.bind s p n))
      (when (< x 0)
        (abort 'bind)))
    (let (x (c.listen s 10))
      (when (< x 0)
        (abort 'listen)))
    s))

(define accept (s)
  (let (s (c.accept s nil nil))
    (when (< s 0)
      (abort 'accept))
    s))

(define BUFFER_SIZE 1024)

(define receive (s)
  (let (b (ffi.new "char[?]" BUFFER_SIZE)
        x (c.read s b BUFFER_SIZE))
    (when (< x 0)
      (abort))
    (when (> x 0)
      (ffi.string b))))

(define send (b s)
  (let (x (c.write s b (# b)))
    (when (< x 0)
      (abort))
    x))

(define POLLIN          0x0001)
(define POLLOUT         0x0004)
(define POLLERR         0x0008)
(define POLLHUP         0x0010)
(define POLLNVAL        0x0020)

(define threads (obj))

(define error? (v)
  (> v 0x0007))

(define enter (f s rest: vs)
  (let (v (apply bit.bor vs)
        t (thread f))
    (set (get threads s) (list t s v))))

(define leave (s)
  (set (get threads s) nil)
  (close s))

(define go (t x)
  (let (|b,e| (resume t x))
    (unless b
      (pr "error:" e))))

(define polls ()
  (let (ps ())
    (each (_ (t s v)) threads
      (let (p (ffi.new "struct pollfd"))
        (set p.fd s)
        (set p.events v)
        (add ps p)))
    ps))

(define tick (a n)
  (for (i n)
    (let ((fd: s revents: v) (get a i)
          (t) (get threads s))
      (if (or (dead? t) (error? v))
          (leave s)
          (> v 0) (go t s)))))

(define loop ()
  (while (not (empty? threads))
    (let (p (polls)
          n (# p)
          a (ffi.new "struct pollfd[?]" n p))
      (c.poll a n -1)
      (tick a n))))
