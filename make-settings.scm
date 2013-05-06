;;;; generate settings.scm from variables given on the command line


(use irregex srfi-13)


(for-each
 (lambda (arg)
   (cond ((string-index arg #\=) =>
	  (lambda (i)
	    (pp `(define-constant ,(string->symbol (substring arg 0 i))
		   ,(substring arg (add1 i))))))
	 (else 
	  (error "invalid argument" arg))))
 (command-line-arguments))
