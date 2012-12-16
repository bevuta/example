(use jni android-native-app android-activity)



(init-window-callback
 (lambda (app)
   (with-jvm-thread (activity-jvm (native-app-activity app))
     (lambda ()
       (let* ((activity-class (get-object-class (activity-object (native-app-activity app))))
	      (class-loader (call-object-method activity-class
						(method java.lang.Class java.lang.ClassLoader getClassLoader)
						(make-jvalue-array 0)))
	      (R (call-object-method class-loader 
				     (method java.lang.ClassLoader java.lang.Class findClass java.lang.String)
				     (let ((values (make-jvalue-array 1)))
				       (set-object-jvalue! values 0 (jstring "com/bevuta/androidChickenTest/R")))))

	      (layout (call-object-method class-loader 
				     (method java.lang.ClassLoader java.lang.Class findClass java.lang.String)
				     (let ((values (make-jvalue-array 1)))
				       (set-object-jvalue! values 0 (jstring "com/bevuta/androidChickenTest/R$layout")))))
	      (main-layout-id    (get-static-int-field layout (get-static-field layout "main" "I"))))

	 (print R)
	 (print layout)
	 (print main-layout-id))))))

