;; FIXME: this is needed for some reason
(define %##sys#find-extension ##sys#find-extension)
(define (##sys#find-extension p inc?)
  (or (%##sys#find-extension p inc?)
      (%##sys#find-extension (string-append "lib" p) inc?)))

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
  (let* ((ConcurrentLinkedQueue/instance    (field backend 'eventQueue))
	 (Event/class                       (class com.bevuta.androidChickenTest.NativeChicken$Event))
	 (ConcurrentLinkedQueue.poll/method (method java.util.concurrent.ConcurrentLinkedQueue java.lang.Object poll))
	 (Event/instance                    (call-object-method ConcurrentLinkedQueue/instance ConcurrentLinkedQueue.poll/method #f)))

    (jprint Event/instance)

    (delete-local-ref ConcurrentLinkedQueue/instance)
    (delete-local-ref Event/class)
    (delete-local-ref Event/instance)))


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
