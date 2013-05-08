(define this #f)
(define shared-jni-env #f)

(include "scm/init.scm")

(jimport com.bevuta.androidChickenTest.Backend (prefix <> Backend-))
(jimport java.util.concurrent.locks.ReentrantLock (prefix (only <> lock unlock) ReentrantLock-))
(jimport java.util.concurrent.locks.Condition (prefix <> Condition-))

(define-callback com.bevuta.androidChickenTest.Backend onClick ((jobject view))
  (jni-env shared-jni-env)
  (print (to-string view))
  (let ((clazz (class com.bevuta.androidChickenTest.NativeChicken))
        (queue (Backend-argumentsQueue this))
        (handler (Backend-handler this)))
    (send-invoke-msg queue handler clazz "randomChange" '() (Backend-activity this) '()))
  0)

(define-callback com.bevuta.androidChickenTest.Backend onCreate ()
  (print "create callback")
  0)

(define-callback com.bevuta.androidChickenTest.Backend onStart ()
  (print "start callback")
  0)

(define-callback com.bevuta.androidChickenTest.Backend onResume ()
  (print "resume callback")
  0)

(define-callback com.bevuta.androidChickenTest.Backend onPause ()
  (print "pause callback")
  0)

(define-callback com.bevuta.androidChickenTest.Backend onStop ()
  (print "stop callback")
  0)

(define-callback com.bevuta.androidChickenTest.Backend onDestroy ()
  (print "destroy callback")
  0)

(enable-gc-logging #t)
(set-gc-report! #t)

(define-method (com.bevuta.androidChickenTest.Backend.main backend) void
  (set! this backend)
  (set! shared-jni-env (jni-env))
  (print "hello from backend!")  

  (ReentrantLock-lock   (Backend-lock this))
  (Condition-signal     (Backend-chickenReady this))
  (ReentrantLock-unlock (Backend-lock this))
  
  (dispatch))

(return-to-host)
