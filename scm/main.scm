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
  (case event
    ((0) 
     (thread-sleep! 5)
     (print "lifecycle event"))))


(define-method (com.bevuta.androidChickenTest.Backend.main backend) void
  (this backend)
  (print "hello from backend!")
  
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
