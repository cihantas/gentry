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

(define db-con (sqlite3-connect #:database "db.sqlite"))

;; Enable SQLite foreign key support.
(query-exec db-con "PRAGMA foreign_keys = ON")



;; MIGRATIONS

(query-exec db-con #<<sql
    CREATE TABLE IF NOT EXISTS topics (
        id    INTEGER PRIMARY KEY,
        title TEXT    UNIQUE NOT NULL
    );
sql
)

(query-exec db-con #<<sql
    CREATE TABLE IF NOT EXISTS posts (
        id        INTEGER PRIMARY KEY,
        topic_id  INTEGER NOT NULL,
        title     TEXT    NOT NULL,
        message   TEXT    NOT NULL,
        posted_at TEXT    NOT NULL,

        FOREIGN KEY (topic_id) REFERENCES topics(id)
            ON UPDATE CASCADE
            ON DELETE CASCADE
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
    INSERT OR IGNORE INTO posts (title, message, topic_id, posted_at)
    VALUES ('First Post', 'Lorem...', 1, CURRENT_TIMESTAMP),
           ('Second Post', 'Ipsum!', 1, CURRENT_TIMESTAMP),
           ('Third Post', 'Dolor!', 1, CURRENT_TIMESTAMP),
           ('Fourth  Post', 'Sit!', 2, CURRENT_TIMESTAMP);
sql
)



;; MODELS & REPOSITORIES

(struct post (author-id title message posted-at))

(define (make-post #:author_id )


(struct topic (id title))

(define (all-posts-by-topic-title title)
  (query-rows db-con
    #<<sql
    SELECT posts.* FROM posts
    JOIN topics ON topics.id = posts.topic_id
    WHERE topics.title = $1
    ORDER BY posts.posted_at DESC
sql
    title))



;; ROUTES

(define-values (router url)
	(dispatch-rules
		[("t" (string-arg)) list-topic-posts]
		[("t" (string-arg) (string-arg)) not-found]
    [else not-found]))



;; REQUEST HANDLERS

;; Wraps a response/xexpr into the main layout -> response/xexpr.
(define (layout/main . content)
  (response/xexpr
    `(html
       (head
         (link ([href "/gentry.css"] [rel "stylesheet"])))
       (body ,@content))))

;; Lists all posts of the topic.
(define (list-topic-posts req topic)
  (layout/main
    `(strong "list-topic-posts on " ,topic)))

;; Shows a 404 Not Found error message.
(define (not-found req)
  (layout/main
    `(strong "Not found.")))



;; LIFTOFF!
(serve/servlet router
               #:port 1234
               #:command-line? #t
               #:extra-files-paths (list ".")
               #:servlet-regexp #rx"")
