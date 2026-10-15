;;; A Helix plugin for switching and toggling booleans.

(require "convert.scm")

(require (only-in "helix/editor.scm"
                  editor-focus
                  editor->doc-id
                  editor->text))

(require (only-in "helix/static.scm"
                  current-selection-object
                  selection->ranges
                  selection->primary-index
                  set-current-selection-object!
                  set-current-selection-primary-index!
                  push-range-to-selection!
                  replace-selection-with
                  range
                  range->selection
                  range->from
                  range->to
                  range-anchor
                  range-head))

(require (only-in "helix/misc.scm"
                  set-error!))

(require-builtin helix/core/text)

(provide switch-boolean
         set-boolean-positive
         set-boolean-negative
         toggle-boolean
         set-boolean-true
         set-boolean-false)

(define (any? pred lst)
  (cond
    [(null? lst) #f]
    [(pred (car lst)) #t]
    [else (any? pred (cdr lst))]))

;; Transforms the current selection(s) using the specified boolean mode.
;; If a selection does not fit any boolean word directly, attempts to match
;; the word at the cursor/selection ("match-in-word").
;; If after that the filter still does not match, sets an error and does
;; nothing with the selection.
(define (transform-selection-boolean! mode-fn error-msg)
  (define selection (current-selection-object))
  (define doc-id (editor->doc-id (editor-focus)))
  (define rope (editor->text doc-id))
  (define full-text (rope->string rope))
  (define ranges (selection->ranges selection))

  ;; Process each selection range:
  ;; e: (list target-range from to old-text new-text matched?)
  (define candidate-edits
    (map (lambda (r)
           (define orig-from (range->from r))
           (define orig-to (range->to r))
           (define orig-text (rope->string (rope->slice rope orig-from orig-to)))
           ;; 1. Check if the current selection directly matches the filter
           (define direct-match (transform-boolean-str orig-text mode-fn))
           (if direct-match
               ;; Matched directly
               (list r orig-from orig-to orig-text direct-match #t)
               ;; 2. Filter doesn't match: try match-in-word and try again
               (let ([wb (find-word-bounds full-text orig-from orig-to)])
                 (if wb
                     (let* ([w-from (car wb)]
                            [w-to (cdr wb)]
                            [word-text (substring full-text w-from w-to)]
                            [word-match (transform-boolean-str word-text mode-fn)])
                       (if word-match
                           ;; Matched in word: construct range preserving selection direction
                           (let ([word-range (if (<= (range-anchor r) (range-head r))
                                                 (range w-from w-to)
                                                 (range w-to w-from))])
                             (list word-range w-from w-to word-text word-match #t))
                           ;; Filter still doesn't match after match-in-word
                           (list r orig-from orig-to orig-text orig-text #f)))
                     ;; No word boundary found
                     (list r orig-from orig-to orig-text orig-text #f)))))
         ranges))

  (define any-matched?
    (any? (lambda (e) (list-ref e 5)) candidate-edits))

  (if (not any-matched?)
      ;; If after that the filter still doesn't match, return an error and do nothing with the selection
      (set-error! error-msg)
      ;; Else do whatever the selected mode was
      (let* ([edits (map (lambda (e)
                           (list (list-ref e 0)
                                 (list-ref e 1)
                                 (list-ref e 2)
                                 (list-ref e 3)
                                 (list-ref e 4)))
                         candidate-edits)]
             [changed (filter (lambda (e) (not (string=? (list-ref e 3) (list-ref e 4)))) edits)])
        (if (not (null? changed))
            (begin
              ;; Edit ranges back-to-front
              (for-each (lambda (e)
                          (set-current-selection-object! (range->selection (list-ref e 0)))
                          (replace-selection-with (list-ref e 4)))
                        (reverse changed))

              ;; Unchanged ranges move too, so walk all of them front-to-back with accumulated deltas
              (define shifted
                (let loop ([es edits] [delta 0] [acc '()])
                  (if (null? es)
                      (reverse acc)
                      (let* ([e (car es)]
                             [r (list-ref e 0)]
                             [old-len (- (list-ref e 2) (list-ref e 1))]
                             [new-len (string-length (list-ref e 4))]
                             [from (+ (list-ref e 1) delta)])
                        (loop (cdr es)
                              (+ delta (- new-len old-len))
                              (cons (if (<= (range-anchor r) (range-head r))
                                        (range from (+ from new-len))
                                        (range (+ from new-len) from))
                                    acc))))))

              (set-current-selection-object! (range->selection (car shifted)))
              (for-each push-range-to-selection! (cdr shifted))
              (set-current-selection-primary-index! (selection->primary-index selection)))
            ;; Text didn't change (e.g. positive mode on already positive boolean).
            ;; If any selection was expanded from cursor to word, update selection to cover the word.
            (let ([ranges (map (lambda (e) (list-ref e 0)) edits)])
              (set-current-selection-object! (range->selection (car ranges)))
              (for-each push-range-to-selection! (cdr ranges))
              (set-current-selection-primary-index! (selection->primary-index selection)))))))

;;@doc
;; Switch boolean
(define (switch-boolean)
  (transform-selection-boolean! switch-boolean-word "No boolean found to switch"))

;;@doc
;; Turn boolean positive
(define (set-boolean-positive)
  (transform-selection-boolean! boolean-to-positive-word "No boolean found to set positive"))

;;@doc
;; Turn boolean negative
(define (set-boolean-negative)
  (transform-selection-boolean! boolean-to-negative-word "No boolean found to set negative"))

;; Aliases for user convenience
(define toggle-boolean switch-boolean)
(define set-boolean-true set-boolean-positive)
(define set-boolean-false set-boolean-negative)
