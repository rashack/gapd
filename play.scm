#!/usr/bin/guile \
--debug -e main -s
!#

(add-to-load-path (dirname (current-filename)))
(use-modules (system foreign)
             (rnrs bytevectors)
             ((libmpg123) #:renamer (symbol-prefix-proc 'mp3:))
             ((libao) #:renamer (symbol-prefix-proc 'lao:)))

(define (println fmt-str . args)
  (if args
      (display (apply format (append (list #f fmt-str) args)))
      (display (apply format (list #f fmt-str))))
  (newline))

(define (get-file args)
  (if (< (length args) 2)
      (begin (display "nothing to play\n")
             (exit 1))
      (cadr args)))

(define (main args)
  (let ((file (get-file args)))
    (display (format #f "trying to play file: ~s\n" file))
    (play-file file)
    (newline)))

(define (init-libao)
  (lao:initialize)
  (lao:default-driver-id))

(define (init-mpg123)
  (mp3:init)
  (mp3:new %null-pointer (intptr)))

(define (intptr)
  (bytevector->pointer (make-bytevector 4)))

(define (*uint32 ptr)
  (bytevector-u32-native-ref (pointer->bytevector ptr 4) 0))

(define (set-ao-format mh)
  (let* ((rate     (intptr)) ;; long or int?
         (channels (intptr))
         (encoding (intptr)))
    (mp3:getformat mh rate channels encoding)
    (println "rate: ~s\nchannels: ~s\nencoding: ~s"
             (*uint32 rate)
             (*uint32 channels)
             (*uint32 encoding))
    (let* ((encint (*uint32 encoding))
           (bits (* 8 (mp3:encsize encint))))
      (println "bits: ~s" bits)
      (make-c-struct ao-sample-format
                     (list bits
                           (*uint32 rate)
                           (*uint32 channels)
                           4
                           (intptr))))))

;; int  bits; /* bits per sample */
;; int  rate; /* samples per second (in a single channel) */
;; int  channels; /* number of audio channels */
;; int  byte_format; /* Byte ordering in sample, see constants below */
;; char *matrix; /* input channel location/ordering */
(define ao-sample-format
  (list int int int int '*))

(define (print-ao-sample-format format)
  (println "sample format ~s"
           (parse-c-struct format ao-sample-format)))

(define (log-some buffer-size format driver)
  (println "buffer-size: ~s" buffer-size)
  (println "format: ~s" format)
  (println "driver: ~s" driver)
  (print-ao-sample-format format)
  )

(define (play-file file)
  (display (format #f "playing file: ~s\n" file))
  (let* ((driver (init-libao))
         (mh (init-mpg123))
         (buffer-size (mp3:outblock mh))
         (buffer (bytevector->pointer (make-bytevector buffer-size)))
         (_void1 (mp3:open mh (string->pointer file)))
         (format (set-ao-format mh))
         (dev (lao:open-live driver format %null-pointer))
         (donep (bytevector->pointer (make-bytevector 4 0))))
    (log-some buffer-size format driver)
    (let lp ((read (mp3:read mh buffer buffer-size donep)))
      (if (= 0 read)
          (begin
            (lao:play dev buffer (*uint32 donep)) ;(bytevector-u32-native-ref donep))
            (lp (mp3:read mh buffer buffer-size donep)))))
    (println "done: ~s\nread: ~s" donep read)))
