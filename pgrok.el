;;; pgrok.el --- Project Grokking for Emacs

;; Copyright (C) 2008  Juri Pakaste
;; Copyright (C) 1985, 1986, 1987, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
;;   2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008
;;   Free Software Foundation, Inc.

;; Author: Juri Pakaste <juri@iki.fi>
;; Location: http://www.juripakaste.fi/pgrok/
;; Version: 0.1

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; pgrok loads project settings from specially named files (see
;; variable `pgrok-project-file') in the same directory as the file
;; you are opening or an ancestor directory. It also contains some
;; functions for dealing with projects, using the directory where a
;; project file was found as the project directory (see variable
;; `pgrok-project-directory'). If you wish to customize the variable,
;; you can do it in one of the project files, because they are
;; evaluated after setting the variable.
;;
;; pgrok does not support nested projects.
;;
;; To use pgrok, add `pgrok-load-project-files' to `find-file-hook', a
;; major mode hook, or run `pgrok-load-project-files' by hand.
;;
;; Modified from Kai Großjohann's version at 
;; http://www.emacswiki.org/cgi-bin/wiki/ProjectSettings

(defvar pgrok-project-file ".emacs-prj"
  "Name and prefix for project files.
Emacs looks for file by this name loads it if it finds it in the
current directory or its parents (it uses the file found in the
first directory while walking up the tree.) Additionally it looks
for a file with this name after appending a dash and the major
mode name, like .emacs-prj-python.

The files must reside in the same directory. The first directory
where either one is found is used.")

(defvar pgrok-project-directory (expand-file-name "~")
  "The current project directory.")

(make-variable-buffer-local 'pgrok-project-directory)

(defun pgrok-find-project-file (dir mode-name)
  "Returns a three element list of (directory mode-specific-file
general-file) for the first directory in the hierarchy where one
of them is found. The file names are absolute. If one of the
files wasn't found, in its place nil is returned."
  (let* ((f (expand-file-name (concat pgrok-project-file "-" mode-name) dir))
         (bf (expand-file-name pgrok-project-file dir))
         (parent (file-truename (expand-file-name ".." dir)))
         (fex (file-exists-p f))
         (bfex (file-exists-p bf)))
    (cond ((string= dir parent) nil)
          ((or fex bfex) (list dir 
                               (if fex f nil) 
                               (if bfex bf nil)))
          (t (pgrok-find-project-file parent mode-name)))))

(defun pgrok-load-project-files ()
  "Evaluates project setting files (see `pgrok-project-file') in
the current directory or one of its ancestors. To use pgrok, you
should add this function to a mode hook or find-file-hook."
  (interactive)
  (let* ((mfull (symbol-name major-mode))
         (mode-name (if (string-match "\\`\\(.*\\)-mode\\'" mfull)
                        (match-string 1 mfull)
                      mfull))
         (pfile (pgrok-find-project-file default-directory mode-name)))
    (when pfile
      (destructuring-bind (dir mfile bfile) pfile
        (set 'pgrok-project-directory dir)
        (progn
          (when bfile (load bfile))
          (when mfile (load mfile)))))))

(defun pgrok-find-dired (args)
  "Run `find' and go into Dired mode showing the output. This is
the same as `find-dired', except that instead of accepting a
directory argument, `pgrok-project-directory' is used."
  (interactive (list (read-string "Run find (with args): " find-args
				  '(find-args-history . 1))))
  (find-dired pgrok-project-directory args))

(defun pgrok-rgrep (regexp &optional files)
  "Recursively grep for regexp in files in the project tree. This
is the same as `rgrep', except that it feeds in
`pgrok-project-directory' as the default directory."
  (interactive
   (progn
     (grep-compute-defaults)
     (cond
      ((and grep-find-command (equal current-prefix-arg '(16)))
       (list (read-from-minibuffer "Run: " grep-find-command
				   nil nil 'grep-find-history)
	     nil))
      ((not grep-find-template)
       (list nil nil
	     (read-string "pgrok.el: No `grep-find-template' available. Press RET.")))
      (t (let* ((regexp (grep-read-regexp))
		(files (grep-read-files regexp)))
	   (list regexp files))))))
   (rgrep regexp files pgrok-project-directory))

(provide 'pgrok)
