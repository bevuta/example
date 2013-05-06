(define %find-extension ##sys#find-extension)
(set! ##sys#find-extension
  (lambda (p inc?)
    (or (%find-extension p inc?)
	(%find-extension (string-append "lib" p) inc?))))

(use android-log)
(enable-gc-logging #t)
(import-for-syntax jni)
(use jni posix srfi-18 matchable concurrent-native-callbacks)

;TODO: to be improved!
(begin-for-syntax
 (if (not (jni-env))
     (jvm-init-lolevel
      (string-join
       (list
	"androidChickenTest/bin/classes"
	"../android-chicken/build/target/data/data/com.bevuta.androidChickenTest/lib/chicken/7/jni-utils.jar"
	(string-append SDK_PATH "/platforms/android-14/android.jar"))
       ":"))))

(jni-init)

(define-foreign-variable JNI_VERSION_1_6 int)

(define get-jvm (foreign-lambda* (c-pointer void) ()
                  "C_return(jvm);"))

(let-location ((env (c-pointer void)))
              (jvm-env (get-jvm) (location env) JNI_VERSION_1_6)
              (jni-env env))

(jimport com.bevuta.androidChickenTest.Backend (prefix <> Backend-))
(jimport com.bevuta.androidChickenTest.MethodArguments (prefix <> MethodArguments-))
(jimport java.util.concurrent.locks.ReentrantLock (prefix (only <> lock unlock) ReentrantLock-))
(jimport java.util.concurrent.locks.Condition (prefix <> Condition-))
(jimport java.util.concurrent.ConcurrentLinkedQueue (prefix <> Queue-))
(jimport android.os.Message (prefix <> Message-))
(jimport android.os.Handler (prefix <> Handler-))
(jimport android.os.Bundle (prefix <> Bundle-))

(set-gc-report! #t)

#>
void Java_com_bevuta_androidChickenTest_Backend_signalToScheme(JNIEnv *env, jobject *this, int eventcode) {
  signal_to_scheme(eventcode);
}
<#

(define this
  (make-parameter #f))

(define global-this #f)

(define-synchronous-concurrent-native-callback (signal_to_scheme (int eventcode)) int
  (this global-this)
  (print "I got signal number " eventcode)
  (call/cc 
    (lambda (k)
      (with-exception-handler (lambda (x) (k -1))
                              (lambda () (handle-event eventcode) 0)))))

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

(define (send-invoke-msg clazz method-name instance args)
  (let* ((signature (list->array (class java.lang.Class) (list)))
         (msg       (Message-new))
         (bundle    (Bundle-new))
         (args      (MethodArguments-new instance (list->array (class java.lang.Object) args))))
    (Bundle-putSerializable bundle "class" clazz)
    (Bundle-putSerializable bundle "signature" signature)
    (Bundle-putString bundle "methodName" method-name)
    (Message-setData msg bundle)
    (Queue-add (Backend-argumentsQueue (this)) args)
    (Handler-sendMessage (Backend-handler (this)) msg)))

(define (on-click-callback)
  (let ((clazz (class com.bevuta.androidChickenTest.NativeChicken)))
    (send-invoke-msg clazz "randomChange" (Backend-activity (this)) '())))

(define-method (com.bevuta.androidChickenTest.Backend.main backend) void

  (this backend)
  (set! global-this backend)
  (print "hello from backend!")  

  (register-callback 'create  create)
  (register-callback 'start   start)
  (register-callback 'resume  resume)
  (register-callback 'pause   pause)
  (register-callback 'stop    stop)
  (register-callback 'destroy destroy)
  (hash-table-set! callbacks 5000 on-click-callback)

  (ReentrantLock-lock   (Backend-lock (this)))
  (Condition-signal     (Backend-chickenReady (this)))
  (ReentrantLock-unlock (Backend-lock (this)))
  
  (dispatch))

(return-to-host)
