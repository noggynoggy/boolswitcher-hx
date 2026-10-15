;;; String to boolean conversion and word boundary detection.
;;; No editor dependencies.

(provide positive-words
         negative-words
         boolean-word?
         switch-boolean-word
         boolean-to-positive-word
         boolean-to-negative-word
         transform-boolean-str
         word-char?
         find-word-bounds)

(define positive-words
  (list "true" "True" "TRUE"
        "yes" "Yes" "YES"
        "y" "Y" "1"))

(define negative-words
  (list "false" "False" "FALSE"
        "no" "No" "NO"
        "n" "N" "0"))

(define (index-of-string lst target)
  (let loop ([xs lst] [idx 0])
    (cond
      [(null? xs) #f]
      [(string=? (car xs) target) idx]
      [else (loop (cdr xs) (+ idx 1))])))

;; Returns #t if w is any recognized boolean keyword, #f otherwise.
(define (boolean-word? w)
  (or (integer? (index-of-string positive-words w))
      (integer? (index-of-string negative-words w))))

;; Switch mode: true <-> false, yes <-> no, y <-> n, 1 <-> 0, etc.
(define (switch-boolean-word w)
  (cond
    [(index-of-string positive-words w) => (lambda (i) (list-ref negative-words i))]
    [(index-of-string negative-words w) => (lambda (i) (list-ref positive-words i))]
    [else #f]))

;; Positive mode: turns negative booleans into positive, keeps positive booleans as is.
(define (boolean-to-positive-word w)
  (cond
    [(index-of-string positive-words w) => (lambda (i) (list-ref positive-words i))]
    [(index-of-string negative-words w) => (lambda (i) (list-ref positive-words i))]
    [else #f]))

;; Negative mode: turns positive booleans into negative, keeps negative booleans as is.
(define (boolean-to-negative-word w)
  (cond
    [(index-of-string positive-words w) => (lambda (i) (list-ref negative-words i))]
    [(index-of-string negative-words w) => (lambda (i) (list-ref negative-words i))]
    [else #f]))

;; Peel off leading whitespace, returning (reversed-whitespace . rest).
(define (span-whitespace cs)
  (let loop ([cs cs] [acc '()])
    (if (and (pair? cs) (char-whitespace? (car cs)))
        (loop (cdr cs) (cons (car cs) acc))
        (cons acc cs))))

;; Split a string into (list leading-whitespace core-word trailing-whitespace).
(define (split-whitespace s)
  (define lead (span-whitespace (string->list s)))
  (define tail (span-whitespace (reverse (cdr lead))))
  (list (list->string (reverse (car lead)))
        (list->string (reverse (cdr tail)))
        (list->string (car tail))))

;; Transforms a string `s` using `mode-fn`, preserving leading and trailing whitespace.
;; Returns the modified string if `s` contains a valid boolean word, or #f if it doesn't match.
(define (transform-boolean-str s mode-fn)
  (define parts (split-whitespace s))
  (define lead (list-ref parts 0))
  (define core (list-ref parts 1))
  (define tail (list-ref parts 2))
  (define res (mode-fn core))
  (if res
      (string-append lead res tail)
      #f))

;; Returns #t if character c is an alphanumeric character or underscore.
(define (word-char? c)
  (or (and (char>=? c #\a) (char<=? c #\z))
      (and (char>=? c #\A) (char<=? c #\Z))
      (and (char>=? c #\0) (char<=? c #\9))
      (char=? c #\_)))

;; Finds word boundaries (start . end) in `text` enclosing or touching [from, to].
;; Returns (cons start end) if inside a word, or #f if not touching a word character.
(define (find-word-bounds text from to)
  (define len (string-length text))
  (if (or (<= len 0) (< from 0) (>= from len))
      #f
      (let ([anchor (cond
                      [(and (< from len) (word-char? (string-ref text from))) from]
                      [(and (> to from) (< (- to 1) len) (word-char? (string-ref text (- to 1)))) (- to 1)]
                      [else #f])])
        (if (not anchor)
            #f
            (let* ([start (let loop ([i anchor])
                            (if (and (> i 0) (word-char? (string-ref text (- i 1))))
                                (loop (- i 1))
                                i))]
                   [end (let loop ([i (+ anchor 1)])
                          (if (and (< i len) (word-char? (string-ref text i)))
                              (loop (+ i 1))
                              i))])
              (cons start end))))))
