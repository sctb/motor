;; -*- mode: lisp -*-

(define-c |
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
|)

(define-local pq (ffi.load 'pq))

(define-local abort (p name)
  (let (e (ffi.string (pq.PQerrorMessage p)))
    (error (cat (or name 'error) ": " e))))

(define connected? (p)
  (= (pq.PQstatus p) pq.CONNECTION_OK))

(define connect (s t)
  (let (p (pq.PQconnectdb s))
    (unless (connected? p)
      (abort p 'connect))
    (let (x (pq.PQsetnonblocking p 1))
      (unless (= x 0)
        (abort p 'connect)))
    (let (fd (pq.PQsocket p))
      (enter fd: fd
             thread: t
             state: p
             final: finish))
    p))

(define-local finish (p)
  (pq.PQfinish p))

(define-local reset (p)
  (pq.PQreset p)
  (unless (connected? p)
    (abort p 'reset)))

(define-local consume (p fd)
  (wait fd POLLIN)
  (let (x (pq.PQconsumeInput p))
    (when (= x 0)
      (abort p 'consume))))

(define-local status (r)
  (let (x (pq.PQresultStatus r))
    (when (> x pq.PGRES_TUPLES_OK)
      (ffi.string (pq.PQresultErrorMessage r)))))

(define-local clear (r)
  (pq.PQclear r))

(define-local send-query (p fd q)
  (let (x (pq.PQsendQuery p q))
    (when (= x 0)
      (abort p 'query)))
  (let (sent #f)
    (while (not sent)
      (wait fd POLLOUT)
      (let (x (pq.PQflush p))
        (if (< x 0) (abort p 'query)
            (= x 0) (set sent #t))))))

(define-local get-results (p fd)
  (let (rs ())
    (while #t
      (if (= (pq.PQisBusy p) 0)
          (let (r (pq.PQgetResult p))
            (if (nil? r) (break) (add rs r)))
        (consume p fd)))
    rs))

(define query (p q)
  (let (fd (pq.PQsocket p))
    (send-query p fd q)
    (let (rs (get-results p fd))
      (each (_ s) (map status rs)
        (pr s))
      (map clear rs))))
