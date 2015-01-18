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
  (let (fd (c.socket PF_INET SOCK_STREAM IPPROTO_TCP))
    (when (< fd 0)
      (abort 'socket))
    fd))

(define close (fd)
  (when (< (c.close fd) 0)
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

(define accept (fd)
  (let (s (c.accept fd nil nil))
    (when (< s 0)
      (abort 'accept))
    s))

(define BUFFER_SIZE 1024)

(define receive (fd)
  (let (b (ffi.new "char[?]" BUFFER_SIZE)
        x (c.read fd b BUFFER_SIZE))
    (when (< x 0)
      (abort))
    (when (> x 0)
      (ffi.string b))))

(define send (b fd)
  (let (x (c.write fd b (# b)))
    (when (< x 0)
      (abort))
    x))

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

(define tick (a n)
  (for (i n)
    (let ((:fd revents: r) (get a i))
      (when (> r 0)
        (if (error? r) (leave fd)
          (let (c (get threads fd)
                |b,e| (resume c fd r))
            (unless b
              (pr "error:" e))
            (when (or (not b) (dead? c))
              (leave fd))))))))

(define loop ()
  (while (some? polls)
    (let (n (# polls)
          s (map poll polls)
          a (ffi.new "struct pollfd[?]" n s))
      (c.poll a n -1)
      (tick a n))))
