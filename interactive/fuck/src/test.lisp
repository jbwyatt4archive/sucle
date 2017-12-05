(defpackage :atest
  (:use :cl
	:fuktard))
(in-package :atest)
(defparameter *box* #(0 128 0 128 -128 0))
(with-unsafe-speed
  (defun map-box (func &optional (box *box*))
    (declare (type (function (fixnum fixnum fixnum)) func)
	     (type simple-vector box))
    (etouq
     (with-vec-params (quote (x0 x1 y0 y1 z0 z1)) (quote (box))
		      (quote (dobox ((x x0 x1)
				     (y y0 y1)
				     (z z0 z1))
				    (funcall func x y z)))))))

(defun grassify (x y z)
  (let ((blockid (world:getblock x y z)))
    (when (= blockid 3)
      (let ((idabove (world:getblock x (1+ y) z)))
	(when (zerop idabove)
	  (sandbox::plain-setblock x y z 2 0))))))

(defun dirts (x y z)
  (let ((blockid (world:getblock x y z)))
    (when (= blockid 1)
      (when (or (zerop (world:getblock x (+ 2 y) z))
		(zerop (world:getblock x (+ 3 y) z)))
	(sandbox::plain-setblock x y z 3 0)))))

(defun find-top (x z min max test)
  (let ((delta (- max min)))
    (dotimes (i delta)
      (let* ((height (- max i 1))
	     (obj (funcall test x height z)))
	(when obj
	  (return-from find-top (values height obj)))))
    (values nil nil)))

(defun enclose ()
  (dobox ((x 0 128)
	  (y 0 128))
	 (sandbox::plain-setblock x y -1   1 0)
	 (sandbox::plain-setblock x y -2   1 0)
	 (sandbox::plain-setblock x y -127 1 0)
	 (sandbox::plain-setblock x y -128 1 0))
  (dobox ((z -128 0)
	  (y 0 128))
	 (sandbox::plain-setblock 0   y z 1 0)
	 (sandbox::plain-setblock 1   y z 1 0)
	 (sandbox::plain-setblock 127 y z 1 0)
	 (sandbox::plain-setblock 126 y z 1 0))
  (dobox ((z -128 0)
	  (x 0 128)
	  (y 0 64))
	 (sandbox::plain-setblock x y z 1 0)))

(defun simple-relight (&optional (box *box*))
  (map-box (lambda (x y z)
	     (let ((blockid (world:getblock x y z)))
					;(unless (zerop blockid))
	       (let ((light (aref mc-blocks:*lightvalue* blockid)))
		 (if (zerop light)
		     (sandbox::plain-setblock x y z blockid 0 0)
		     (sandbox::plain-setblock x y z blockid light)))))
	   box)
  (map-box (lambda (x y z)
	     (multiple-value-bind (height obj)
		 (find-top x z 0 y (lambda (x y z)
				     (not (zerop (world:getblock x y z)))))
	       (declare (ignore obj))
	       (unless height
		 (setf height 0))
	       (dobox ((upup (1+ height) y))
		      (world:skysetlight x upup z 15))))
	   #(0 128 128 129 -128 0))
  (map-box (lambda (x y z)
	     (when (= 15 (world:skygetlight x y z))
	       (sandbox::sky-light-node x y z)))
	   *box*)
  (map-box (lambda (x y z)
	     (unless (zerop (world:getblock x y z))
	       (sandbox::light-node x y z)))
	   *box*))

(defun invert (x y z)
  (let ((blockid (world:getblock x y z)))
    (if (= blockid 0)
	(sandbox::plain-setblock x y z 1 ;(aref #(56 21 14 73 15) (random 5))
			0)
	(sandbox::plain-setblock x y z 0 0)
	)))

(defun neighbors (x y z)
  (let ((tot 0))
    (macrolet ((aux (i j k)
		 `(unless (zerop (world:getblock (+ x ,i) (+ y ,j) (+ z ,k)))
		   (incf tot))))
      (aux 1 0 0)
      (aux -1 0 0)
      (aux 0 1 0)
      (aux 0 -1 0)
      (aux 0 0 1)
      (aux 0 0 -1))
    tot))

(defun bonder (x y z)
  (let ((blockid (world:getblock x y z)))
    (unless (zerop blockid)
      (let ((naybs (neighbors x y z)))
	(when (> 3 naybs)		     
	  (sandbox::plain-setblock x y z 0 0 0))))))

(defun bonder2 (x y z)
  (let ((blockid (world:getblock x y z)))
    (when (zerop blockid)
      (let ((naybs (neighbors x y z)))
	(when (< 2 naybs)		     
	  (sandbox::plain-setblock x y z 1 0 0))))))

(defun invert-light (x y z)
  (when (zerop (world:getblock x y z))
    (let ((blockid2 (world:skygetlight x y z)))
      (Setf (world:skygetlight x y z) (- 15 blockid2)))))

(defun edge-bench (x y z)
  (let ((blockid (world:getblock x y z)))
    (unless (zerop blockid)
      (when (= 4 (neighbors x y z))
	(sandbox::plain-setblock x y z 58 0 0)))))

(defun corner-obsidian (x y z)
  (let ((blockid (world:getblock x y z)))
    (unless (zerop blockid)
      (when (= 3 (neighbors x y z))
	(sandbox::plain-setblock x y z 49 0 0)))))


(defun seed (id chance)
  (declare (type (unsigned-byte 8) id))
  (lambda (x y z)
    (let ((blockid (world:getblock x y z)))
      (when (and (zerop blockid)
		 (zerop (random chance)))
	(sandbox::plain-setblock x y z id 0)))))

(defun grow (old new)
  (lambda (x y z)
    (let ((naybs (neighbors2 x y z old)))
      (when (and (not (zerop naybs))
		 (zerop (world:getblock x y z))
		 (zerop (random (- 7 naybs))))
	(sandbox::plain-setblock x y z new 0)))))
(defun sheath (old new)
  (lambda (x y z)
    (let ((naybs (neighbors2 x y z old)))
      (when (and (not (zerop naybs))
		 (zerop (world:getblock x y z)))
	(sandbox::plain-setblock x y z new 0)))))

(defun neighbors2 (x y z w)
  (let ((tot 0))
    (macrolet ((aux (i j k)
		 `(when (= w (world:getblock (+ x ,i) (+ y ,j) (+ z ,k)))
		   (incf tot))))
      (aux 1 0 0)
      (aux -1 0 0)
      (aux 0 1 0)
      (aux 0 -1 0)
      (aux 0 0 1)
      (aux 0 0 -1))
    tot))

(defun testes (&optional (box *box*))
  (map nil
       (lambda (x) (map-box x box))
       (list #'edge-bench
	     #'corner-obsidian
	     (replace-block 49 0)
	     (replace-block 58 0))))

(defun replace-block (other id)
  (declare (type (unsigned-byte 8) id))
  (lambda (x y z)
    (let ((blockid (world:getblock x y z)))
      (when (= other blockid)
	(world:setblock x y z id)))))

(defun dirt-sand (x y z)
  (let ((blockid (world:getblock x y z)))
    (case blockid
      (2 (sandbox::plain-setblock x y z 12 0))
      (3 (sandbox::plain-setblock x y z 24 0)))))

(defun cactus (x y z)
  (let ((trunk-height (+ 1 (random 3))))
    (dobox ((y0 0 trunk-height))
	   (sandbox::plain-setblock (+ x 0) (+ y y0) (+ z 0) 81 0 0))))

(defun growdown (old new)
  (lambda (x y z)
    (flet ((neighbors3 (x y z w)
	     (let ((tot 0))
	       (macrolet ((aux (i j k)
			    `(when (= w (world:getblock (+ x ,i) (+ y ,j) (+ z ,k)))
			       (incf tot))))
		 (aux 1 0 0)
		 (aux -1 0 0)
		 (aux 0 1 0)
		 (aux 0 0 1)
		 (aux 0 0 -1))
	       tot)))
      (let ((naybs (neighbors3 x y z old)))
	(when (and (not (zerop naybs))
		   (zerop (world:getblock x y z))
		   (zerop (random (- 7 naybs))))
	  (sandbox::plain-setblock x y z new 0))))))

#+nil
#(1 2 3 4 5 7 12 13 ;14
  15 16 17 18 19 21 22 23 24 25 35 41 42 43 45 46 47 48 49
   54 56 57 58 61 61 73 73 78 82 84 86 87 88 89 91 95)

#+nil
'("lockedchest" "litpumpkin" "lightgem" "hellsand" "hellrock" "pumpkin"
 "jukebox" "clay" "snow" "oreRedstone" "oreRedstone" "furnace" "furnace"
 "workbench" "blockDiamond" "oreDiamond" "chest" "obsidian" "stoneMoss"
 "bookshelf" "tnt" "brick" "stoneSlab" "blockIron" "blockGold" "cloth"
 "musicBlock" "sandStone" "dispenser" "blockLapis" "oreLapis" "sponge" "leaves"
 "log" "oreCoal" "oreIron" "oreGold" "gravel" "sand" "bedrock" "wood"
 "stonebrick" "dirt" "grass" "stone")

#+nil
(defun define-time ()
  (eval
   (defun fine-time ()
      (/ (%glfw::get-timer-value)
	 ,(/ (%glfw::get-timer-frequency) (float (expt 10 6)))))))

#+nil
(defun seeder ()
  (map nil
       (lambda (ent)
	 (let ((pos (sandbox::farticle-position (sandbox::entity-particle ent))))
	   (setf (sandbox::entity-fly? ent) nil
		 (sandbox::entity-gravity? ent) t)
	   (setf (aref pos 0) 64.0
		 (aref pos 1) 128.0
		 (aref pos 2) -64.0))) *ents*))

#+nil
(map nil (lambda (ent)
	   (unless (eq ent *ent*)
	     (setf (sandbox::entity-jump? ent) t)
	     (if (sandbox::entity-hips ent)
		 (incf (sandbox::entity-hips ent)
		       (- (random 1.0) 0.5))
		 (setf (sandbox::entity-hips ent) 1.0))
	     )
	   (sandbox::physentity ent)) *ents*)


#+nil
(progno
 (dotimes (x (length fuck::*ents*))
   (let ((aaah (aref fuck::*ents* x)))
     (unless (eq aaah fuck::*ent*)
       (gl:uniform-matrix-4fv
	pmv
	(cg-matrix:matrix* (camera-matrix-projection-view-player camera)
			   (compute-entity-aabb-matrix aaah partial))
	nil)
       (gl:call-list (getfnc :box))))))

(defun yoy ()
  (world:clearworld)
  (map-box (seed 3 800))
  (dotimes (x 5)
    (map-box (sheath 3 4))
    (map-box (sheath 4 3)))
  (map-box #'bonder))

(defun upsheath (old new)
  (lambda (x y z)
    (flet ((neighbs (x y z w)
	     (let ((tot 0))
	       (macrolet ((aux (i j k)
			    `(when (= w (world:getblock (+ x ,i) (+ y ,j) (+ z ,k)))
			       (incf tot))))
		 (aux 1 0 0)
		 (aux -1 0 0)
		 (aux 0 -1 0)
		 (aux 0 0 1)
		 (aux 0 0 -1))
	       tot)))
      (let ((naybs (neighbs x y z old)))
	(when (and (not (zerop naybs))
		   (zerop (world:getblock x y z)))
	  (sandbox::plain-setblock x y z new 0))))))

