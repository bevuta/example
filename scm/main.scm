(define this #f)
(define shared-jni-env #f)

(include "scm/init.scm")

(jimport com.bevuta.androidChickenTest.Backend (prefix <> Backend-))
(jimport java.util.concurrent.locks.ReentrantLock (prefix (only <> lock unlock) ReentrantLock-))
(jimport java.util.concurrent.locks.Condition (prefix <> Condition-))

(define-callback com.bevuta.androidChickenTest.Backend signal ((int eventcode)) int
  (print "I got signal number " eventcode)
  (jni-env shared-jni-env)
  (call/cc 
    (lambda (k)
      (with-exception-handler (lambda (x) (k -1))
                              (lambda () (handle-event eventcode) 0)))))

(define-callback com.bevuta.androidChickenTest.Backend onClickCallback ((jobject view)
                                                                        (int c)) int
  (jni-env shared-jni-env)
  (print (to-string view))
  (let ((clazz (class com.bevuta.androidChickenTest.NativeChicken))
        (queue (Backend-argumentsQueue this))
        (handler (Backend-handler this)))
    (send-invoke-msg queue handler clazz "randomChange" '() (Backend-activity this) '()))
  0)

(enable-gc-logging #t)
(set-gc-report! #t)

(define (handle-event event)
  (let ((callback (hash-table-ref callbacks event)))
    (print (format "dispatching callback ~A: ~A with ()" event callback))
    (if callback (callback) (error "Chicken Backend" "undefined callback id"))))

(define (create)
  (print "create callback"))
(define (start)
  (print "start callback"))
(define (resume)
  (print "resume callback"))
(define (pause)
  (print "pause callback"))
(define (stop)
  (print "stop callback"))
(define (destroy)
  (print "destroy callback"))

(define callbacks (make-hash-table))

(define callback-counter
  (let ((x 0)) (lambda () (set! x (+ x 1)))))

(define (register-callback name proc)
  (let ((callback-id (callback-counter))
        (field-name  (string->symbol (string-append (symbol->string name) "CallbackId"))))
    (hash-table-set! callbacks callback-id proc)
    (set! ((jlambda-field-imple #f 'int 'com.bevuta.androidChickenTest.Backend field-name) this) callback-id)))

(define-method (com.bevuta.androidChickenTest.Backend.main backend) void
  (set! this backend)
  (set! shared-jni-env (jni-env))
  (print "hello from backend!")  

  (register-callback 'create  create)
  (register-callback 'start   start)
  (register-callback 'resume  resume)
  (register-callback 'pause   pause)
  (register-callback 'stop    stop)
  (register-callback 'destroy destroy)

  (ReentrantLock-lock   (Backend-lock this))
  (Condition-signal     (Backend-chickenReady this))
  (ReentrantLock-unlock (Backend-lock this))
  
  (dispatch))

(return-to-host)
