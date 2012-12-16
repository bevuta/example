;; FIXME: this is needed for some reason
(define %##sys#find-extension ##sys#find-extension)
(define (##sys#find-extension p inc?)
  (or (%##sys#find-extension p inc?)
      (%##sys#find-extension (string-append "lib" p) inc?)))

(use jni  android-log posix srfi-18)

(jni-init)

(define-method (com.bevuta.androidChickenTest.Backend.main this) void
  (print "hello from backend!")

  (receive (in out) (create-pipe)
    (set-int-field this
                   (get-field (get-object-class this) "signalFd" (type-signature int))
                   out)
    (thread-start! (lambda ()
                     (let loop ()
                       (print "hello from another thread")
                       (thread-sleep! 1)
                       (loop))))

    (let ((in* (open-input-file* in)))
      (let loop ()
        (thread-wait-for-i/o! in)
        (read-char in*)
        (let ((o (call-object-method (get-object-field
                                      this
                                      (get-field (get-object-class this)
                                                 "eventQueue"
                                                 (type-signature java.util.concurrent.ConcurrentLinkedQueue)))
                                     (method java.util.concurrent.ConcurrentLinkedQueue
                                             java.lang.Object
                                             poll)
                                     (make-jvalue-array 0))))
          (print "got event: " (jstring->string (get-object-field o (get-field (get-object-class o) "eventType" (type-signature java.lang.String))))
                 " on " (get-object-field o (get-field (get-object-class o) "eventTarget" (type-signature java.lang.Object)))))
        (loop)))))

(foreign-declare "
void Java_com_bevuta_androidChickenTest_Backend_signal(JNIEnv *env, jobject *this) {
  jfieldID signalFdField = (*env)->GetFieldID(env, (*env)->GetObjectClass(env, this), \"signalFd\", \"I\");
  int fd = (*env)->GetIntField(env, this, signalFdField);
  write(fd, \"x\", 1);
  return;
}
")

(return-to-host)
