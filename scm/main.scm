(use android-log posix srfi-18 jni jni-reflection
     matchable)

(jni-init)
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
    (set-field! (this) field-name callback-id)))

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

  (receive (in out) (create-pipe)
    (set-field! backend 'signalFd out)

    (let ((in* (open-input-file* in)))
      (call (field backend 'lock) 'lock)
      (call (field backend 'chickenReady) 'signal)
      (call (field backend 'lock) 'unlock)

      (let loop ()
	(thread-wait-for-i/o! in)
		
	(read-char in*)
	(handle-event (field backend 'eventType))
	
	(call (field backend 'lock) 'lock)
	(call (field backend 'chickenReady) 'signal)
	(call (field backend 'lock) 'unlock)

        (loop)))))

(return-to-host)
