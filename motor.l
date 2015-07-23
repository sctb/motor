;; -*- mode: lisp -*-

(define ffi (require 'ffi))
(define buffer (require 'buffer))

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

int setsockopt(
  int socket,
  int level,
  int option_name,
  const void *option_value,
  socklen_t option_len);

typedef uint8_t sa_family_t;
typedef uint16_t in_port_t;
typedef uint32_t in_addr_t;

struct in_addr {
  in_addr_t     s_addr;
};

uint16_t htons(uint16_t hostshort);
uint32_t htonl(uint32_t hostlong);

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

(require 'system)

(define cstr ffi.string)
(define c ffi.C)

(define abort (name)
  (let e (cstr (c.strerror (ffi.errno)))
    (error (cat (or name 'error) ": " e))))

(define AF_INET 2)
(define SOCK_STREAM 1)
(define IPPROTO_TCP 6)
(define INADDR_ANY 0)

(define socket ()
  (with fd (c.socket AF_INET SOCK_STREAM IPPROTO_TCP)
    (when (< fd 0)
      (abort 'socket))
    (let (a (ffi.new "int[1]" 1)
          n (ffi.sizeof "int")
          x (c.setsockopt fd SOL_SOCKET SO_REUSEADDR a n))
      (when (< x 0)
        (abort 'setsockopt)))))

(define bind (port)
  (with fd (socket)
    (let (p (ffi.new "struct sockaddr_in[1]")
          n (ffi.sizeof "struct sockaddr_in")
          a (get p 0))
      (set a.sin_family AF_INET)
      (set a.sin_port (c.htons port))
      (set a.sin_addr.s_addr (c.htonl INADDR_ANY))
      (let (p (ffi.cast "struct sockaddr*" p)
            x (c.bind fd p n))
        (when (< x 0)
          (abort 'bind)))
      (let x (c.listen fd 10)
        (when (< x 0)
          (abort 'listen))))))

(define POLLNONE 0x0000)
(define POLLIN 0x0001)
(define POLLOUT 0x0004)
(define POLLERR 0x0008)
(define POLLHUP 0x0010)
(define POLLNVAL 0x0020)

(define threads ())

(define error? (v)
  (> v 0x0007))

(define close (fd)
  (when (< (c.close fd) 0)
    (abort 'close)))

(define active (fd)
  (get (get threads fd) 'thread))

(define enter (fd thread final)
  (let (f (or final (fn () (close fd)))
        x (list fd: fd
                thread: thread
                final: f
                events: POLLNONE))
    (set (get threads fd) x)))

(define leave (fd)
  (let x (get threads fd)
    (x.final))
  (set (get threads fd) nil))

(define cleanup ()
  (each (fd x) threads
    (leave fd)))

(define dead? (c)
  (= (coroutine.status c) 'dead))

(define run (t fd)
  (let |b,e| (resume t)
    (unless b
      (print (cat "error:" e)))
    (when (dead? t)
      (leave fd))))

(define polls ()
  (with ps ()
    (each x threads
      (let (p (ffi.new "struct pollfd"))
        (set p.fd x.fd)
        (set p.events x.events)
        (add ps p)))))

(define tick (a n)
  (for i n
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

(define loop ()
  (while (not (empty? threads))
    (let (p (polls)
          n (# p)
          a (ffi.new "struct pollfd[?]" n p)
          t (timeout p))
      (c.poll a n t)
      (tick a n))))

(define start ()
  (let ((x e) (guard (loop)))
    (when e
      (print (cat "error: " e))))
  (cleanup))

(define F_SETFL 4)
(define O_NONBLOCK 0x0004)

(define accept (fd)
  (with fd (c.accept fd nil nil)
    (when (< fd 0)
      (abort 'accept))
    (c.fcntl fd F_SETFL O_NONBLOCK)))

(define wait (fd o)
  (let (x (get threads fd)
        v (if (= o 'out) POLLOUT POLLIN))
    (set x.events v))
  (yield))

(define listen (port f)
  (let fd (bind port)
    (define connect ()
      (wait fd)
      (let (fd (accept fd)
            f (fn () (f fd)))
        (enter fd (thread f)))
      (connect (yield)))
    (enter fd (thread connect))))

(define read (fd b)
  (wait fd)
  (let n (buffer.space b)
    (when (> n 0)
      (let p (buffer.pointer b)
        (with x (c.read fd p n)
          (when (< x 0)
            (abort 'read))
          (inc b.length x))))))

(define receive (fd)
  (let (b (buffer.create)
        n (read fd b))
    (when (> n 0)
      (buffer.string b))))

(define write (fd p n)
  (wait fd 'out)
  (with x (c.write fd p n)
    (when (< x 0)
      (abort 'send))))

(define send (fd s)
  (let (i 0 n (# s)
        b (ffi.cast "const char*" s))
    (while (< i n)
      (let x (write fd (+ b i) (- n i))
        (inc i x)))))

(export active
        enter
        wait
        listen
        read
        receive
        write
        send
        start)
