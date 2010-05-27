;;;; Created on 2009-02-02 20:14:32

(defpackage :hh-aws-tests
  (:use :cl :asdf :lisp-unit :hh-utils :hh-aws)
   )

(in-package :hh-aws-tests)

(define-test create-list-delete-domain-test
  (let ( 
        (new-domain-name (hh-utils:detokenize (list
                                               (uuid-string)
                                               "unittest"
                                               "codeplume.com" 
                                               ) "."
                                              )
                         )
        )
    (assert-true (string-ends-with new-domain-name ".unittest.codeplume.com"))
    (assert-true (db-create-domain new-domain-name))
    (assert-true (member new-domain-name 
                         (db-list-domains) 
                         :test #'equal
                         )
                 )

    (assert-true (db-delete-domain new-domain-name))
    (assert-false (member new-domain-name 
                         (db-list-domains) 
                         :test #'equal
                         )
                 )
    )
  )

(define-test put-get-query-delete-attributes-test
  (let ( 
        (domain-name (hh-utils:detokenize (list
                                           (uuid-string)
                                           "unittest"
                                           "codeplume.com" 
                                           ) "."
                                          )
                     )
        (item-name-1 (uuid-string))
        )
    (assert-true (string-ends-with domain-name ".unittest.codeplume.com"))
    (assert-true (db-create-domain domain-name))
    
    (assert-true (db-put-attributes domain-name item-name-1
                                    `(
                                      ("foo" "bar")
                                      ("baz" "wazoo")
                                      )
                                    )
                 )
    (let ( (attributes (db-get-attributes domain-name item-name-1)) )
      (assert-true (every (lambda (a)
                            (member a attributes :test #'equal)
                            )
                          `(
                            ("foo" "bar")
                            ("baz" "wazoo")
                            )
                          )
                   )
      )
    
    (assert-equal (db-query domain-name "['foo'='bar']")
                  `( ,item-name-1 )
                  )
    
    (let ( (item (car (db-query-with-attributes domain-name "" ()))) )
      (assert-true (every (lambda (a)
                            (member a item :test #'equal)
                            )
                          `(,item-name-1 ("foo" "bar")
                                         ("baz" "wazoo")
                                         )
                          )
                   )
      )
    
    (let ( 
          (item (car (db-query-with-attributes domain-name "" '("foo"))) ) 
          )
      (assert-true (every (lambda (a)
                            (member a item :test #'equal)
                            )
                          `(,item-name-1 ("foo" "bar")
                                         )
                          )
                   )
      (assert-false (member '("baz" "wazoo") item :test #'equal))
      )
    
    (let ( 
          (item (car (db-select (format-string "select foo from `~a`" 
                                               domain-name)
                                )
                     ) 
                ) 
          )
      (assert-true (every (lambda (a)
                            (member a item :test #'equal)
                            )
                          `(,item-name-1 ("foo" "bar")
                                         )
                          )
                   )
      (assert-false (member '("baz" "wazoo") item :test #'equal))
      )
    
    (assert-true (db-delete-attributes domain-name item-name-1 ()))
    
    (assert-false (db-get-attributes domain-name item-name-1))
    
    (db-delete-domain domain-name)
    (assert-false (member domain-name 
                          (db-list-domains) 
                          :test #'equal
                          )
                  )
    )
  )

(define-test create-delete-bucket-test
  (let ( 
        (bucket-name (hh-utils:detokenize (list
                                           (format-string "~4,'0D" (random 1000))
                                           "unittest"
                                           "codeplume-com" 
                                           ) "-"
                                          )
                     ) 
        )
    (assert-true (s3-create-bucket bucket-name))
    (assert-true (member bucket-name (s3-list-buckets) :test #'equal))
    (assert-true (s3-delete-bucket bucket-name))
    (assert-false (member bucket-name (s3-list-buckets) :test #'equal))
    )
  )

(define-test put-get-delete-bucket-object-test
  (let ( 
        (bucket-name (hh-utils:detokenize (list
                                           (format-string "~4,'0D" (random 1000))
                                           "unittest"
                                           "codeplume-com" 
                                           ) "-"
                                          )
                     )
        (object-name (hh-utils:detokenize (list
                                           "object"
                                           (format-string "~4,'0D" (random 1000))
                                           ) "-"
                                          )
                     ) 
        )
    (assert-true (s3-create-bucket bucket-name))
    (assert-true (member bucket-name (s3-list-buckets) :test #'equal))
    
    (assert-true (s3-put-bucket-object bucket-name object-name "foo!"))
    (assert-equal (s3-get-bucket-object bucket-name object-name)
                  "foo!"
                  )
    
    (assert-error 'hh-aws::bucket-not-empty
                  (s3-delete-bucket bucket-name)
                  )
    
    (assert-true (s3-delete-bucket-object bucket-name object-name))
    
    (assert-true (s3-delete-bucket bucket-name))
    (assert-false (member bucket-name (s3-list-buckets) :test #'equal))
    )
  )

(run-tests)