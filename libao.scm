(define-module (libao)
  #:use-module (system foreign))

(define libao (dynamic-link "libao"))

(define-syntax-rule (deffi name return c-name args)
  (define-public name
    (pointer->procedure return (dynamic-func c-name libao) args)))

(deffi initialize
  void "ao_initialize" '())

(deffi default-driver-id
  int "ao_default_driver_id" '()) ;; driver

(deffi open-live
  '* "ao_open_live" (list int '* '*)) ;; ao_device, driver format NULL

(deffi play
  void "ao_play" (list '* '* size_t)) ;; dev buffer done

(deffi close
  void "ao_close" '(*)) ;; dev

(deffi shutdown
  void "ao_shutdown" '())
