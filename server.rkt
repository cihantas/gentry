#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/templates)

(struct post (title body))

(define topic (list (post "Genesis" "The day Gentry was born.")))


; (define (render-post post)
;     ())

(define (app req)
    (response/output (include-template "index.html")))

(serve/servlet app
               #:port 1234
               #:launch-browser? #f
               #:servlet-regexp #rx"")