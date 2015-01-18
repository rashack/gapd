(define-module (libmpg123)
  #:use-module (system foreign))

(define libmpg123 (dynamic-link "libmpg123"))

(define-syntax-rule (deffi name return c-name args)
  (define-public name
    (pointer->procedure return (dynamic-func c-name libmpg123) args)))

(deffi init
  void "mpg123_init" '())

(deffi new
  '* "mpg123_new" '(* *)) ;; handle, NULL error-code

(deffi outblock
  size_t "mpg123_outblock" '(*)) ;; buffer size, handle

(deffi open
  void "mpg123_open" '(* *)) ;; handle file

(deffi getformat
  void "mpg123_getformat" '(* * * *)) ;; handle rate channels encoding

(deffi encsize
  uint8 "mpg123_encsize" (list int)) ;; bytes per sample, encoding

(deffi read
  int "mpg123_read" (list '* '* int '*)) ;; 0 if ok (MPG123_OK), mh buffer buffer_size done

(deffi close
  void "mpg123_close" '(*)) ;; handle

(deffi delete
  void "mpg123_delete" '(*)) ;; handle

(deffi exit
  void "mpg123_exit" '(*)) ;; handle
