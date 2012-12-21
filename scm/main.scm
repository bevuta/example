(use android-log posix srfi-18 jni jni-reflection)

(jni-init)
#>
void Java_com_bevuta_androidChickenTest_Backend_signal(JNIEnv *env, jobject *this) {
  jfieldID signalFdField = (*env)->GetFieldID(env, (*env)->GetObjectClass(env, this), "signalFd", "I");
  int fd = (*env)->GetIntField(env, this, signalFdField);
  write(fd, "x", 1);
  return;
}
<#

(define (handle-event backend)
  (jprint (call (field backend 'eventQueue) 'poll)))


(define-method (com.bevuta.androidChickenTest.Backend.main this) void
  (print "hello from backend!")
  (receive (in out) (create-pipe)
    (set-field! this 'signalFd out)
    (let ((in* (open-input-file* in)))
      (let loop ()
        (thread-wait-for-i/o! in)
        (read-char in*)
	(handle-event this)
        (loop)))))

(return-to-host)
