 
(progno
 (defun char-read (path)
   (with-open-file (stream path :element-type 'base-char)
     (let* ((len (file-length stream))
	    (data (make-array len :element-type 'base-char)))
       (dotimes (n len)
	 (setf (aref data n) (read-char stream)))
       data)))
 (defparameter *data* (char-read "/home/imac/Documents/stuff2/file.osgjs"))
 #+nil(defparameter *data2* (sandbox::byte-read "/home/imac/Documents/stuff2/model_file.bin"))


 (funland:with-unsafe-speed
   (defun float-array (offset size &optional (data *data2*))
     (declare (type (simple-array (unsigned-byte 8)) data))
     (let ((array (make-array size :element-type 'single-float)))
       (dotimes (x size)
	 (let ((base (+ offset (* x 4))))
	   (let ((payload (logior
			   (aref data (+ base 0))
			   (ash (aref data (+ base 1)) 8)
			   (ash (aref data (+ base 2)) 16)
			   (ash (aref data (+ base 3)) 24))))
	     (let ((ans (ieee-floats:decode-float32 payload)))
	       (print ans)
	       (setf (aref array x)
		     ans)))))
       array)))

 (defun print-bits (n &optional (stream *standard-output*))
   (terpri)
   (format stream "~17,'0b" n)
   n)

 (defun read-varint-uint32 (offset data)
   (declare (type (simple-array (unsigned-byte 8)) data))
   (let ((acc 0)
	 (index 0)
	 (bit-offset 0))
     (loop
	(let ((byte (aref data (+ index offset))))
	  (setf acc (logior acc (ash (mod byte 128) bit-offset)))
	  (incf index)
	  (unless (logbitp 7 byte)
	    (return))
	  (incf bit-offset 7)))
     (values acc index)))

 (defun uint32-array (offset size &optional (data *data2*))
   (declare (type (simple-array (unsigned-byte 8)) data))
   (let ((array (make-array size :element-type '(unsigned-byte 32))))
     (let ((base offset))
       (dotimes (index size)
	 (multiple-value-bind (num bytesize) (read-varint-uint32 base data)
	   (incf base bytesize)
	   (setf (aref array index)
		 num)))
       (values array base))))
 (defparameter testx (make-array 2 :element-type '(unsigned-byte 8) :initial-contents
				 '(#b10101100 #b00000010))))
(defparameter *json-data*
  (with-input-from-string (x *data*)
    (cl-json:decode-json x)))


((:OSG.*GEOMETRY (:*UNIQUE-+ID+ . 2)
           (:*PRIMITIVE-SET-LIST
            ((:*DRAW-ELEMENTS-U-INT (:*UNIQUE-+ID+ . 12)
              (:*INDICES (:*UNIQUE-+ID+ . 13)
               (:*ARRAY
                (:*UINT-32-*ARRAY (:*FILE . "model_file.bin.gz")
                 (:*SIZE . 83523) (:*OFFSET . 0) (:*ENCODING . "varint")))
               (:*ITEM-SIZE . 1) (:*TYPE . "ELEMENT_ARRAY_BUFFER"))
              (:*MODE . "TRIANGLE_STRIP")))
            ((:*DRAW-ELEMENTS-U-INT (:*UNIQUE-+ID+ . 14)
              (:*INDICES (:*UNIQUE-+ID+ . 15)
               (:*ARRAY
                (:*UINT-32-*ARRAY (:*FILE . "model_file.bin.gz")
                 (:*SIZE . 29142) (:*OFFSET . 131524) (:*ENCODING . "varint")))
               (:*ITEM-SIZE . 1) (:*TYPE . "ELEMENT_ARRAY_BUFFER"))
              (:*MODE . "TRIANGLES"))))
           (:*STATE-SET
            (:OSG.*STATE-SET (:*UNIQUE-+ID+ . 3)
             (:*TEXTURE-ATTRIBUTE-LIST
              (((:OSG.*TEXTURE (:*UNIQUE-+ID+ . 5)
                 (:*FILE
                  . "textures/8ad0fd34f30c445f99436e94a2a5aa6e/dd8cdbbada8c4d41b007a4fa5aa846e8.png")
                 (:*MAG-FILTER . "LINEAR")
                 (:*MIN-FILTER . "LINEAR_MIPMAP_LINEAR") (:*WRAP-S . "REPEAT")
                 (:*WRAP-T . "REPEAT")))))
             (:*USER-DATA-CONTAINER (:*UNIQUE-+ID+ . 4)
              (:*VALUES ((:*NAME . "UniqueID") (:*VALUE . "1"))))))
           (:*USER-DATA-CONTAINER (:*UNIQUE-+ID+ . 6)
            (:*VALUES ((:*NAME . "attributes") (:*VALUE . "55"))
             ((:*NAME . "vertex_bits") (:*VALUE . "16"))
             ((:*NAME . "vertex_mode") (:*VALUE . "3"))
             ((:*NAME . "uv_0_bits") (:*VALUE . "14"))
             ((:*NAME . "uv_0_mode") (:*VALUE . "3"))
             ((:*NAME . "epsilon") (:*VALUE . "0.25"))
             ((:*NAME . "nphi") (:*VALUE . "720"))
             ((:*NAME . "triangle_mode") (:*VALUE . "7"))
             ((:*NAME . "vertex_obits") (:*VALUE . "16"))
             ((:*NAME . "vtx_bbl_x") (:*VALUE . "-11.609"))
             ((:*NAME . "vtx_bbl_y") (:*VALUE . "-60.0309"))
             ((:*NAME . "vtx_bbl_z") (:*VALUE . "-16.6767"))
             ((:*NAME . "vtx_h_x") (:*VALUE . "0.000715756"))
             ((:*NAME . "vtx_h_y") (:*VALUE . "0.00366222"))
             ((:*NAME . "vtx_h_z") (:*VALUE . "0.00102731"))
             ((:*NAME . "uv_0_bbl_x") (:*VALUE . "0.0019"))
             ((:*NAME . "uv_0_bbl_y") (:*VALUE . "0.0444"))
             ((:*NAME . "uv_0_h_x") (:*VALUE . "0.000121609"))
             ((:*NAME . "uv_0_h_y") (:*VALUE . "0.00011642"))))
           (:*VERTEX-ATTRIBUTE-LIST
            (:*COLOR (:*UNIQUE-+ID+ . 9)
             (:*ARRAY
              (:*FLOAT-32-*ARRAY (:*FILE . "model_file.bin.gz")
               (:*SIZE . 65532) (:*OFFSET . 180204)))
             (:*ITEM-SIZE . 4) (:*TYPE . "ARRAY_BUFFER"))
            (:*NORMAL (:*UNIQUE-+ID+ . 8)
             (:*ARRAY
              (:*UINT-32-*ARRAY (:*FILE . "model_file.bin.gz") (:*SIZE . 65532)
               (:*OFFSET . 1228716) (:*ENCODING . "varint")))
             (:*ITEM-SIZE . 2) (:*TYPE . "ARRAY_BUFFER"))
            (:*TANGENT (:*UNIQUE-+ID+ . 11)
             (:*ARRAY
              (:*UINT-32-*ARRAY (:*FILE . "model_file.bin.gz") (:*SIZE . 65532)
               (:*OFFSET . 1466328) (:*ENCODING . "varint")))
             (:*ITEM-SIZE . 2) (:*TYPE . "ARRAY_BUFFER"))
            (:*TEX-COORD-0 (:*UNIQUE-+ID+ . 10)
             (:*ARRAY
              (:*INT-32-*ARRAY (:*FILE . "model_file.bin.gz") (:*SIZE . 65532)
               (:*OFFSET . 1703380) (:*ENCODING . "varint")))
             (:*ITEM-SIZE . 2) (:*TYPE . "ARRAY_BUFFER"))
            (:*VERTEX (:*UNIQUE-+ID+ . 7)
             (:*ARRAY
              (:*INT-32-*ARRAY (:*FILE . "model_file.bin.gz") (:*SIZE . 65532)
               (:*OFFSET . 1877112) (:*ENCODING . "varint")))
             (:*ITEM-SIZE . 3) (:*TYPE . "ARRAY_BUFFER")))))

(defparameter len (or 600 (length element2)))
(defun unzigzag (x)
  (if (oddp x)
      (/ (1+ x) -2)
      (/ x 2)))

(progno
 (defparameter wow (make-array (ash 1 16)))
 (map nil (lambda (x)
	    (incf (aref wow (+ (ash 1 15) (unzigzag x))))) vertices
	    )

 (defparameter elements (uint32-array 0 83523))
 (defparameter element2 (uint32-array 131524 29142))
 (defparameter vertices (uint32-array 1877112 (* 3 65532))))
(progno
 (defparameter wow2 (make-array (* 3 (ash 1 16))))
 (map nil (lambda (x)
	    (incf (aref wow2 (+ (ash 1 16) (unzigzag x))))) element2
	    ))