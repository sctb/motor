;; -*- mode: lisp -*-

(define ffi (require 'ffi))
(define motor (require 'motor))

(define-c ffi |
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
char *PQcmdStatus(PGresult *res);
char *PQcmdTuples(PGresult *res);
int PQntuples(const PGresult *res);
int PQnfields(const PGresult *res);
char *PQfname(const PGresult *res, int column_number);
char *PQgetvalue(const PGresult *res, int row_number, int column_number);
|)

(define pq ((get ffi 'load) 'pq))
(define cstr (get ffi 'string))

(define abort (p name)
  (let e (cstr ((get pq 'PQerrorMessage) p))
    (error (cat (or name 'error) ": " e))))

(define connected? (p)
  (= ((get pq 'PQstatus) p) (get pq 'CONNECTION_OK)))

(define finish (p)
  ((get pq 'PQfinish) p))

(define connect (s t)
  (let p ((get pq 'PQconnectdb) s)
    (when (connected? p)
      (let x ((get pq 'PQsetnonblocking) p 1)
        (unless (= x 0)
          (abort p 'connect)))
      (when (function? t)
        (let f t
          (set t (thread (fn () (f p))))))
      (let (fd ((get pq 'PQsocket) p)
            f (fn () (finish p)))
        ((get motor 'enter) fd t f))
      p)))

(define consume (p fd)
  ((get motor 'wait) fd)
  (let x ((get pq 'PQconsumeInput) p)
    (when (= x 0)
      (abort p 'consume))))

(define get-rows (res n m)
  (with rs ()
    (for i n
      (let r ()
        (for j m
          (let (k (cstr ((get pq 'PQfname) res j))
                v (cstr ((get pq 'PQgetvalue) res i j)))
            (set (get r k) v)))
        (add rs r)))))

(define result (r)
  (let x ((get pq 'PQresultStatus) r)
    (if (= x (get pq 'PGRES_COMMAND_OK))
        (let a (cstr ((get pq 'PQcmdTuples) r))
          (list command: (cstr ((get pq 'PQcmdStatus) r))
                size: (when (some? a) (number a))))
        (or (= x (get pq 'PGRES_TUPLES_OK))
            (= x (get pq 'PGRES_SINGLE_TUPLE)))
        (let (n ((get pq 'PQntuples) r)
              m ((get pq 'PQnfields) r))
          (list command: (cstr ((get pq 'PQcmdStatus) r))
                size: n
                rows: (get-rows r n m)))
      (list error: (cstr ((get pq 'PQresultErrorMessage) r))))))

(define clear (r)
  ((get pq 'PQclear) r))

(define send-query (p fd q)
  (let x ((get pq 'PQsendQuery) p q)
    (when (= x 0)
      (abort p 'query)))
  (let sent false
    (while (not sent)
      ((get motor 'wait) fd 'out)
      (let (x ((get pq 'PQflush) p))
        (if (< x 0) (abort p 'query)
            (= x 0) (set sent true))))))

(define get-results (p fd)
  (with rs ()
    (while true
      (if (= ((get pq 'PQisBusy) p) 0)
          (let r ((get pq 'PQgetResult) p)
            (if (is? r)
                (add rs r)
              (break)))
        (consume p fd)))))

(define query (p q)
  (let fd ((get pq 'PQsocket) p)
    (send-query p fd q)
    (let rs (get-results p fd)
      (with xs (map result rs)
        (map clear rs)))))

(export connect query)
