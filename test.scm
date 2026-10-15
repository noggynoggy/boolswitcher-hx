;;; Run with: steel test.scm

(require "convert.scm")

(define failures 0)

(define (check label got want)
  (unless (equal? got want)
    (set! failures (+ failures 1))
    (displayln (list "FAIL" label 'got got 'want want))))

;; ─── Test 1: Boolean Pairs Table ────────────────────────────────────────────
;; row: (input switch-expected positive-expected negative-expected)
(define test-table
  (list
   ;; lowercase
   (list "true"  "false" "true"  "false")
   (list "false" "true"  "true"  "false")
   ;; Capitalized
   (list "True"  "False" "True"  "False")
   (list "False" "True"  "True"  "False")
   ;; UPPERCASE
   (list "TRUE"  "FALSE" "TRUE"  "FALSE")
   (list "FALSE" "TRUE"  "TRUE"  "FALSE")
   ;; yes / no variations
   (list "yes"   "no"    "yes"   "no")
   (list "no"    "yes"   "yes"   "no")
   (list "Yes"   "No"    "Yes"   "No")
   (list "No"    "Yes"   "Yes"   "No")
   (list "YES"   "NO"    "YES"   "NO")
   (list "NO"    "YES"   "YES"   "NO")
   ;; single-character abbreviations
   (list "y"     "n"     "y"     "n")
   (list "n"     "y"     "y"     "n")
   (list "Y"     "N"     "Y"     "N")
   (list "N"     "Y"     "Y"     "N")
   ;; numeric booleans
   (list "1"     "0"     "1"     "0")
   (list "0"     "1"     "1"     "0")))

(for-each
 (lambda (row)
   (define input (list-ref row 0))
   (define exp-switch (list-ref row 1))
   (define exp-pos (list-ref row 2))
   (define exp-neg (list-ref row 3))
   (check (list input 'switch) (switch-boolean-word input) exp-switch)
   (check (list input 'positive) (boolean-to-positive-word input) exp-pos)
   (check (list input 'negative) (boolean-to-negative-word input) exp-neg)
   (check (list input 'boolean-word?) (boolean-word? input) #t))
 test-table)

;; ─── Test 2: Non-boolean inputs ─────────────────────────────────────────────
(define non-booleans
  (list "foo" "bar" "maybe" "2" "true1" "false_val" "yesno" "" " " "   "))

(for-each
 (lambda (word)
   (check (list word 'non-bool-switch) (switch-boolean-word word) #f)
   (check (list word 'non-bool-pos) (boolean-to-positive-word word) #f)
   (check (list word 'non-bool-neg) (boolean-to-negative-word word) #f)
   (check (list word 'non-bool-pred) (boolean-word? word) #f)
   (check (list word 'non-bool-str) (transform-boolean-str word switch-boolean-word) #f))
 non-booleans)

;; ─── Test 3: Whitespace Preservation ────────────────────────────────────────
(check 'ws-padded-switch
       (transform-boolean-str "  true  " switch-boolean-word)
       "  false  ")
(check 'ws-newline-switch
       (transform-boolean-str "false\n" switch-boolean-word)
       "true\n")
(check 'ws-tabs-pos
       (transform-boolean-str "\t0\t\n" boolean-to-positive-word)
       "\t1\t\n")
(check 'ws-tabs-neg
       (transform-boolean-str "  TRUE\n" boolean-to-negative-word)
       "  FALSE\n")

;; ─── Test 4: Word Boundary Detection (find-word-bounds) ─────────────────────
(define sample-code "const enabled = false; let count = 1; let flag = True;")
;; indices:
;; "const enabled = false; let count = 1; let flag = True;"
;;  01234567890123456789012345678901234567890123456789012
;; "false" is at 16..21
;; "1" is at 37..38
;; "True" is at 50..54

;; Cursor at 'f' of false (16..17)
(check 'bounds-false-start
       (find-word-bounds sample-code 16 17)
       (cons 16 21))

;; Cursor at 'l' in false (18..19)
(check 'bounds-false-mid
       (find-word-bounds sample-code 18 19)
       (cons 16 21))

;; Cursor at 'e' in false (20..21)
(check 'bounds-false-end
       (find-word-bounds sample-code 20 21)
       (cons 16 21))

;; Slice matches "false"
(check 'slice-false
       (let ([b (find-word-bounds sample-code 16 17)])
         (substring sample-code (car b) (cdr b)))
       "false")

;; Cursor on '1' (35..36)
(check 'bounds-single-digit
       (find-word-bounds sample-code 35 36)
       (cons 35 36))

;; Cursor on semicolon (21..22) -> non-word
(check 'bounds-semicolon
       (find-word-bounds sample-code 21 22)
       #f)

;; Cursor on whitespace (15..16) -> non-word
(check 'bounds-space
       (find-word-bounds sample-code 15 16)
       #f)

;; Full selection already over "True" (49..53)
(check 'bounds-full-word
       (find-word-bounds sample-code 49 53)
       (cons 49 53))

;; ─── Test Result ────────────────────────────────────────────────────────────
(displayln (if (= failures 0) "ok" (list failures "failures")))
