(define %find-extension ##sys#find-extension)
(set! ##sys#find-extension
  (lambda (p inc?)
    (or (%find-extension p inc?)
	(%find-extension (string-append "lib" p) inc?))))

(use android-log)
(import-for-syntax jni chicken scheme)
(use jni posix srfi-18 matchable concurrent-native-callbacks)

(use expand-full)
(begin-for-syntax
  (if (not (jni-env))
    (jvm-init-lolevel
      (string-join
        (list
          "androidChickenTest/bin/classes"
          "../android-chicken/build/target/data/data/com.bevuta.androidChickenTest/lib/chicken/7/jni-utils.jar"
          (string-append SDK_PATH "/platforms/android-14/android.jar"))
        ":"))))

(define (execute-callback thunk)
  (jni-env shared-jni-env)
  (call/cc
    (lambda (k)
      (with-exception-handler (lambda (x) (k -1))
                              (lambda () 
                                (thunk)
                                0)))))

;; generates a native implementation of the java callback method
;; ie: void Java_com.bevuta.androidChickenTest.Backend_onClickCallback(...) 
;; for each of the jobject parameters a new global ref is created, and then
;; the rigth cncb callback is invoked.
(define-for-syntax (generate-callback class name args)
  (let ((class-name  (string-map! (lambda (c)
                                    (if (eq? c #\.)
                                      #\_
                                      c)) (symbol->string class)))
        (native-name (string-append (symbol->string name) "_native"))
        (params      (string-join (append (list "JNIEnv *env" "jobject *this")
                                          (map (lambda (arg)
                                                 (if (eq? (car arg) 'jobject)
                                                   (string-append "jobject* " (symbol->string (cadr arg)))
                                                   (string-append (symbol->string (car arg)) " " (symbol->string (cadr arg)))))
                                               args)) ", ")))
    (with-output-to-string
      (lambda () 
        (printf "void Java_~a_~a(~a)" class-name (symbol->string name) params)
        (printf "{")
        (for-each (lambda (arg i)
                    (if (eq? (car arg) 'jobject)
                      (printf "jobject __arg_~a = (*env)->NewWeakGlobalRef(env, ~a);" i (cadr arg))
                      (printf "~a      __arg_~a = ~a;" (car arg) i (cadr arg)))) 
                  args 
                  (iota (length args)))
        (printf "~a(~a);" native-name (string-join (map (cut format "__arg_~a" <>) (iota (length args))) ", "))
        (for-each (lambda (arg i)
                    (if (eq? (car arg) 'jobject)
                      (printf "(*env)->DeleteWeakGlobalRef(env, __arg_~a);" i)))
                  args
                  (iota (length args)))
        (printf "}")))))

(define-syntax define-callback 
  (er-macro-transformer
    (lambda (x r c)
      (let* ((%define-native-callback (r 'define-synchronous-concurrent-native-callback))
             (%foreign-declare        (r 'foreign-declare))
             (%execute-callback       (r 'execute-callback))
             (class                   (cadr x))
             (name                    (caddr x))
             (args                    (cadddr x))
             (body                    (cddddr x))
             (native-name             (symbol-append name '_native))
             (native-args             (map (lambda (arg)
                                             (if (member (car arg) '(jclass jobject))
                                               (cons '(c-pointer void) (cdr arg))
                                               arg)) args)))
        `(begin
           (,%define-native-callback (,native-name ,@native-args) int
              (,%execute-callback (lambda () ,@body)))
           (,%foreign-declare ,(generate-callback class name args)))))))

(jni-init)

(define-foreign-variable JNI_VERSION_1_6 int)

(define get-jvm (foreign-lambda* (c-pointer void) ()
                  "C_return(jvm);"))

(let-location ((env (c-pointer void)))
              (jvm-env (get-jvm) (location env) JNI_VERSION_1_6)
              (jni-env env))

(jimport android.os.Message (prefix <> Message-))
(jimport android.os.Bundle (prefix <> Bundle-))
(jimport com.bevuta.androidChickenTest.MethodArguments (prefix <> MethodArguments-))
(jimport java.util.concurrent.ConcurrentLinkedQueue (prefix <> Queue-))
(jimport android.os.Handler (prefix <> Handler-))

(define (send-invoke-msg queue handler clazz method-name signature instance args)
  (let* ((signature (list->array (class java.lang.Class) signature))
         (msg       (Message-new))
         (bundle    (Bundle-new))
         (args      (MethodArguments-new instance (list->array (class java.lang.Object) args))))
    (Bundle-putSerializable bundle "class" clazz)
    (Bundle-putSerializable bundle "signature" signature)
    (Bundle-putString bundle "methodName" method-name)
    (Message-setData msg bundle)
    (Queue-add queue args)
    (Handler-sendMessage handler msg)))
