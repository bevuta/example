;; FIXME: this is needed for some reason
(define %##sys#find-extension ##sys#find-extension)
(define (##sys#find-extension p inc?)
  (or (%##sys#find-extension p inc?)
      (%##sys#find-extension (string-append "lib" p) inc?)))

(import-for-syntax jni)
(use jni)

;TODO: to be improved!
(begin-for-syntax
  (if (not (jni-env))
    (jvm-init-lolevel "androidChickenTest/bin/classes:../android-chicken/target/data/data/com.bevuta.androidChickenTest/lib/chicken/6/jni-utils.jar:/opt/android-sdk/platforms/android-14/android.jar")))

(use android-log posix srfi-18 matchable)

(jni-init)

(define-foreign-variable JNI_VERSION_1_6 int)

(define get-jvm (foreign-lambda* (c-pointer void) ()
                  "C_return(jvm);"))

(define (get-env)
  (let-location ((env (c-pointer void)))
                (jvm-env (get-jvm) (location env) JNI_VERSION_1_6)
                env))

(jni-env (get-env))
(jimport java.util.concurrent.locks.ReentrantLock (prefix (only <> lock unlock) ReentrantLock-))
(jimport android.os.Message (prefix <> Message-))
(jimport android.os.Handler (prefix <> Handler-))
(jimport com.bevuta.androidChickenTest.Backend (prefix <> Backend-))
;(jimport android.os.Bundle (prefix <> Bundle-))
;(jimport java.util.concurrent.locks.Condition (prefix <> Condition-))

#>
void Java_com_bevuta_androidChickenTest_Backend_signal(JNIEnv *env, jobject *this) {
  jfieldID signalFdField = (*env)->GetFieldID(env, (*env)->GetObjectClass(env, this), "signalFd", "I");
  int fd = (*env)->GetIntField(env, this, signalFdField);
  write(fd, "x", 1);
  return;
}
<#

(define this
  (make-parameter #f))

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

(define callbacks
  (make-hash-table))

(define callback-counter
  (let ((x 0)) (lambda () (set! x (+ x 1)))))

(define (register-callback name proc)
  (let ((callback-id (callback-counter))
        (field-name  (string->symbol (string-append (symbol->string name) "CallbackId"))))
    (hash-table-set! callbacks callback-id proc)
    (set! ((jlambda-field-imple #f 'int 'com.bevuta.androidChickenTest.Backend field-name) (this)) callback-id)))

(define (on-click-callback)
  (let* ((Bundle-new (jlambda-constructor android.os.Bundle))
         (Bundle-putSerializable (jlambda android.os.Bundle putSerializable))
         (Bundle-putString (jlambda android.os.Bundle putString))
         ;(int-class (jlambda-field (static) java.lang.Class java.lang.Integer TYPE))
         (signature (list->array (class java.lang.Class) (list)))
         (msg       (Message-new))
         (bundle    (Bundle-new)))
    (Bundle-putSerializable bundle "class" (class com.bevuta.androidChickenTest.NativeChicken))
    (Bundle-putSerializable bundle "signature" signature)
    (Bundle-putString bundle "methodName" "randomChange")
    (Message-setData msg bundle)
    (Handler-sendMessage (Backend-handler (this)) msg)))

(define-method (com.bevuta.androidChickenTest.Backend.main backend) void

  (this backend)
  (print "hello from backend!")  

  (set-gc-report! #t)

  (register-callback 'create  create)
  (register-callback 'start   start)
  (register-callback 'resume  resume)
  (register-callback 'pause   pause)
  (register-callback 'stop    stop)
  (register-callback 'destroy destroy)
  (hash-table-set! callbacks 5000 on-click-callback)

  (let ((Condition-signal (jlambda java.util.concurrent.locks.Condition signal)))
    (receive (in out) (create-pipe)
      (set! (Backend-signalFd backend) out)

      (let ((in* (open-input-file* in)))

        (ReentrantLock-lock   (Backend-lock (this)))
        (Condition-signal     (Backend-chickenReady (this)))
        (ReentrantLock-unlock (Backend-lock (this)))

        (let loop ()
          (thread-wait-for-i/o! in)

          (read-char in*)
          (handle-event (Backend-eventType (this)))

          (ReentrantLock-lock   (Backend-lock (this)))
          (Condition-signal     (Backend-chickenReady (this)))
          (ReentrantLock-unlock (Backend-lock (this)))

          (loop))))))

(return-to-host)
