;; -*- mode: lisp -*-

(define ffi (require 'ffi))

(define-c ffi |
int socket(int domain, int type, int protocol);
int fcntl(int fildes, int cmd, ...);

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

(define cstr ffi.string)
(define c ffi.C)

(define abort (name)
  (let (e (cstr (c.strerror (ffi.errno))))
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

(define bind (port)
  (let (fd (socket)
        p (ffi.new "struct sockaddr_in[1]")
        n (ffi.sizeof "struct sockaddr_in")
        a (get p 0))
    (set a.sin_family AF_INET)
    (set a.sin_port (c.htons port))
    (set a.sin_addr.s_addr INADDR_ANY)
    (let (p (ffi.cast "struct sockaddr*" p)
          x (c.bind fd p n))
      (when (< x 0)
        (abort 'bind)))
    (let (x (c.listen fd 10))
      (when (< x 0)
        (abort 'listen)))
    fd))

(define POLLNONE 0x0000)
(define POLLIN 0x0001)
(define POLLOUT 0x0004)
(define POLLERR 0x0008)
(define POLLHUP 0x0010)
(define POLLNVAL 0x0020)

(define threads (obj))

(define error? (v)
  (> v 0x0007))

(define close (fd)
  (when (< (c.close fd) 0)
    (abort 'close)))

(define active (fd)
  (get (get threads fd) 'thread))

(define enter (fd thread final)
  (let (f (or final (fn () (close fd)))
        x (obj fd: fd
               thread: thread
               final: f
               events: POLLNONE))
    (set (get threads fd) x)))

(define leave (fd)
  (let (x (get threads fd))
    (x.final))
  (set (get threads fd) nil))

(define dead? (c)
  (= (coroutine.status c) 'dead))

(define run (t fd)
  (let (|b,e| (resume t))
    (unless b
      (pr "error:" e))
    (when (dead? t)
      (leave fd))))

(define polls ()
  (let (ps ())
    (each (_ x) threads
      (let (p (ffi.new "struct pollfd"))
        (set p.fd x.fd)
        (set p.events x.events)
        (add ps p)))
    ps))

(define tick (a n)
  (for (i n)
    (let ((:fd revents: r) (get a i)
          (thread: t events: v) (get threads fd))
      (if (or (dead? t) (error? r))
          (leave fd)
          (or (= v POLLNONE) (> r 0))
          (run t fd)))))

(define IMMEDIATE 0)
(define NEVER -1)

(define timeout ()
  (if (find (fn (x)
              (= x.events POLLNONE))
            threads)
      IMMEDIATE
    NEVER))

(define start ()
  (while (not (empty? threads))
    (let (p (polls)
          n (# p)
          a (ffi.new "struct pollfd[?]" n p)
          t (timeout p))
      (c.poll a n t)
      (tick a n))))

(define F_SETFL 4)
(define O_NONBLOCK 0x0004)

(define accept (fd)
  (let (fd (c.accept fd nil nil))
    (when (< fd 0)
      (abort 'accept))
    (c.fcntl fd F_SETFL O_NONBLOCK)
    fd))

(define wait (fd o)
  (let (x (get threads fd)
        v (if (= o 'out) POLLOUT POLLIN))
    (set x.events v))
  (yield))

(define listen (port f)
  (let (fd (bind port))
    (define connect ()
      (wait fd)
      (let (fd (accept fd)
            f (fn () (f fd)))
        (enter fd (thread f)))
      (connect (yield)))
    (enter fd (thread connect))))

(define BUFFER_SIZE 1024)

(define receive (fd)
  (wait fd)
  (let (b (ffi.new "char[?]" BUFFER_SIZE)
        x (c.read fd b BUFFER_SIZE))
    (if (< x 0) (abort)
        (> x 0) (cstr b))))

(define send (fd b)
  (let (i 0 n (# b)
        b (ffi.cast "const char*" b))
    (while (< i n)
      (wait fd 'out)
      (let (x (c.write fd (+ b i) (- n i)))
        (when (< x 0)
          (abort))
        (inc i x)))))

(export active
        enter
        wait
        listen
        receive
        send
        start)
