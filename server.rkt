;; MIT License
;;
;; © 2020 Cihan Tas.
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         web-server/templates

         db)



;; INIT

(define db-con (sqlite3-connect #:database 'memory))

;; Enable SQLite foreign key support.
(query-exec db-con "PRAGMA foreign_keys = ON")



;; MIGRATIONS

(query-exec db-con #<<sql
    CREATE TABLE IF NOT EXISTS topics (
        id    INTEGER PRIMARY KEY,
        title TEXT    NOT NULL
    );
sql
)

(query-exec db-con #<<sql
    CREATE TABLE IF NOT EXISTS posts (
        id      INTEGER PRIMARY KEY,
        title   TEXT    NOT NULL,
        message TEXT    NOT NULL 
    );
sql
)

(query-exec db-con #<<sql
    CREATE TABLE IF NOT EXISTS users (
        id            INTEGER PRIMARY KEY,
        author_id     INTEGER NOT NULL,
        name          INTEGER NOT NULL UNIQUE,
        password_hash TEXT    NOT NULL,
        banned_at     TEXT,

        FOREIGN KEY (author_id) REFERENCES users(id)
            ON UPDATE CASCADE
            ON DELETE CASCADE
    );
sql
)

(query-exec db-con #<<sql
    INSERT OR IGNORE INTO topics (title)
    VALUES ('cs'),
           ('gentry');
sql
)

(query-exec db-con #<<sql
    INSERT OR IGNORE INTO posts (title)
    VALUES ('cs'),
           ('gentry');
sql
)



;; MODELS & REPOSITORIES

(struct post (author-id title body created-at))
(struct topic (id title))

(define (all-posts-by-topic-title title)
  (query-exec db-con
    #<<sql
    SELECT posts.* FROM posts
    JOIN topics ON topics.id = posts.topic_id
    WHERE topics.title = $1
    ORDER BY posts.created_at DESC
sql
    title))



;; ROUTES

(define-values (router url)
	(dispatch-rules
		[("t" (string-arg)) list-topic-posts]
		[("t" (string-arg) (string-arg)) not-found]
    [else not-found]))



;; REQUEST HANDLERS

(define (list-topic-posts req topic)
  (response/xexpr
    `(strong "list-topic-posts on" ,topic)))

(define (not-found req)
  (response/xexpr
    `(strong "Not found.")))



;; LIFTOFF!
(serve/servlet router
               #:port 1234
               #:command-line? #t
               #:servlet-regexp #rx"")
