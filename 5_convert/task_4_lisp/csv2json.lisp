(defpackage :csv2json
  (:use :cl)
  (:export :main))

(in-package :csv2json)

(defun parse-csv-line (line)
  (let ((fields '())
        (field (make-string-output-stream))
        (in-quotes nil)
        (i 0)
        (n (length line)))
    (loop while (< i n) do
      (let ((c (char line i)))
        (cond
          ((and in-quotes (char= c #\") (< (1+ i) n) (char= (char line (1+ i)) #\"))
           (write-char #\" field)
           (incf i 2))
          ((and in-quotes (char= c #\"))
           (setf in-quotes nil)
           (incf i))
          ((and (not in-quotes) (char= c #\") (= (file-position field) 0))
           (setf in-quotes t)
           (incf i))
          ((and (not in-quotes) (char= c #\,))
           (push (get-output-stream-string field) fields)
           (setf field (make-string-output-stream))
           (incf i))
          (t
           (write-char c field)
           (incf i)))))
    (push (get-output-stream-string field) fields)
    (nreverse fields)))

(defun read-lines (filename)
  (with-open-file (in filename :direction :input)
    (loop for line = (read-line in nil nil)
          while line
          collect line)))

(defun json-escape (s)
  (with-output-to-string (out)
    (loop for c across s do
      (case c
        (#\" (write-string "\\\"" out))
        (#\\ (write-string "\\\\" out))
        (#\Newline (write-string "\\n" out))
        (#\Tab (write-string "\\t" out))
        (#\Return (write-string "\\r" out))
        (t (write-char c out))))))

(defun fields->json-object (header fields)
  (let ((pairs (mapcar (lambda (h f)
                         (format nil "\"~a\": \"~a\""
                                 (json-escape h)
                                 (json-escape f)))
                       header fields)))
    (format nil "{~{~a~^, ~}}" pairs)))

(defun csv->json (rows)
  (let* ((header (parse-csv-line (first rows)))
         (body (rest rows))
         (objects (mapcar (lambda (line)
                            (fields->json-object header (parse-csv-line line)))
                          body)))
    (format nil "[~%~{~a~^,~%~}~%]~%"
            (mapcar (lambda (o) (concatenate 'string "  " o)) objects))))

(defun main ()
  (let* ((input-file "input.csv")
         (output-file "output.json")
         (lines (read-lines input-file))
         (json (csv->json lines)))
    (with-open-file (out output-file :direction :output
                                      :if-exists :supersede
                                      :if-does-not-exist :create)
      (write-string json out))
    (format t "Input:  ~a~%" input-file)
    (format t "Output: ~a~%" output-file)))

(main)