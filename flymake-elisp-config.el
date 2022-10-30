;;; flymake-elisp-config.el --- Setup load-path for flymake on Emacs Lisp mode  -*- Lexical-binding: t; -*-

;; Copyright (C) 2022  ROCKTAKEY

;; Author: ROCKTAKEY <rocktakey@gmail.com>
;; Keywords: lisp

;; Version: 0.3.1
;; Package-Requires: ((emacs "28.1"))
;; URL: https://github.com/ROCKTAKEY/flymake-elisp-config

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Flymake on Emacs Lisp mode in init.el

;;; Code:

(require 'subr-x)
(require 'project)

(defgroup flymake-elisp-config ()
  "Setup `load-path' for flymake on Emacs Lisp mode."
  :group 'flymake
  :prefix "flymake-elisp-config-"
  :link '(url-link "https://github.com/ROCKTAKEY/flymake-elisp-config"))


;;; `flymake-elisp-config-mode'

(defcustom flymake-elisp-config-load-path-getter #'flymake-elisp-config-get-load-path-default
  "`load-path' used by flymake in current buffer on Emacs Lisp mode."
  :group 'flymake-elisp-config
  :local t
  :type 'function)

(defun flymake-elisp-config-get-load-path ()
  "Get `load-path' for flymake in Emacs Lisp file."
  (funcall flymake-elisp-config-load-path-getter))

(defun flymake-elisp-config-byte-compile (report-fn &rest _args)
  "A Flymake backend for elisp byte compilation.
Spawn an Emacs process that byte-compiles a file representing the
current buffer state and calls REPORT-FN when done."
  (let ((elisp-flymake-byte-compile-load-path
         (flymake-elisp-config-get-load-path)))
    (elisp-flymake-byte-compile report-fn)))

;;;###autoload
(define-minor-mode flymake-elisp-config-mode
  "Provide configurable `load-path' with flymake in Emacs Lisp mode.
Set getter function of `load-path' to `flymake-elisp-config-load-path-getter'."
  :group 'flymake-elisp-config
  (if flymake-elisp-config-mode
      (setq-local flymake-diagnostic-functions
                  (mapcar (lambda (arg)
                            (if (eq arg #'elisp-flymake-byte-compile)
                                #'flymake-elisp-config-byte-compile
                              arg))
                          flymake-diagnostic-functions))
    (setq-local flymake-diagnostic-functions
                (mapcar (lambda (arg)
                          (if (eq arg #'flymake-elisp-config-byte-compile)
                              #'elisp-flymake-byte-compile
                            arg))
                        flymake-diagnostic-functions))))

;;;###autoload
(define-globalized-minor-mode flymake-elisp-config-global-mode
  flymake-elisp-config-mode
  flymake-elisp-config-mode)


;;; `flymake-elisp-config-auto-mode'

(defcustom flymake-elisp-config-auto-load-path-getter-alist
  '((flymake-elisp-config-config-p . flymake-elisp-config-get-load-path-config)
    (flymake-elisp-config-keg-p . flymake-elisp-config-get-load-path-keg))
  "Alist which expresses `load-path' getter on Emacs Lisp mode flymake.
`car' of each element is function which returns non-nil if `cdr' of the element
should be used as getter.  `cdr' of each element is function which returns
`load-path' for flymake on current buffer."
  :group 'flymake-elisp-config
  :type '(alist :key-type function :value-type function))

(defun flymake-elisp-config-auto-configure ()
  "Automatically configure `load-path' for flymake on current Emacs Lisp buffer.
This function scans `flymake-elisp-config-auto-load-path-getter-alist'
to determines `load-path' getter."
  (setq-local flymake-elisp-config-load-path-getter
              (seq-some
               (lambda (cons)
                 (let ((pred (car cons))
                       (getter (cdr cons)))
                   (and (funcall pred)
                        getter)))
               flymake-elisp-config-auto-load-path-getter-alist)))

;;;###autoload
(define-minor-mode flymake-elisp-config-auto-mode
  "Configure flymake appropreately in Emacs Lisp file.
`flymake-elisp-config-global-mode' should be turned on to use this minor mode."
  :global t
  :group 'flymake-elisp-config
  (unless flymake-elisp-config-global-mode
    (warn "`flymake-elisp-config-global-mode' should be turned on when you use `flymake-elisp-config-auto-mode'"))
  (if flymake-elisp-config-auto-mode
      (add-hook 'emacs-lisp-mode-hook #'flymake-elisp-config-auto-configure)
    (remove-hook 'emacs-lisp-mode-hook #'flymake-elisp-config-auto-configure)))


;;; Default `load-path' getter

(defun flymake-elisp-config-get-load-path-default ()
  "Get `elisp-flymake-byte-compile-load-path'."
  elisp-flymake-byte-compile-load-path)

;;;###autoload
(defun flymake-elisp-config-as-default ()
  "Current buffer file is regarded as usual Emacs Lisp file.
`load-path' used by flymake is provided by
`elisp-flymake-byte-compile-load-path'."
  (interactive)
  (flymake-elisp-config-mode)
  (setq flymake-elisp-config-load-path-getter #'flymake-elisp-config-get-load-path-default))


;;; `load-path' getter for Emacs configuration file

(defun flymake-elisp-config-get-load-path-config ()
  "Get `load-path' for flymake in Emacs configuration file."
  (append elisp-flymake-byte-compile-load-path
          load-path))

(defcustom flymake-elisp-config-config-file-name-regexp-list
  (list (concat (regexp-opt
                 '("init.el"
                   ".emacs"
                   ".emacs.el"))
                "$"))
  "Regexp list whose element matches Emacs configuration file, like init.el."
  :group 'flymake-elisp-config
  :type '(repeat string))

(defun flymake-elisp-config-config-file-p (file current-directory regexp-list)
  "Return non-nil if FILE in CURRENT-DIRECTORY is Emacs configuration file.
Each element of REGEXP-LIST, a regular expression, matches Emacs configuration
files."
  (let ((file-fullname (expand-file-name file current-directory)))
    (seq-some
     (lambda (regexp)
       (string-match-p regexp file-fullname))
     regexp-list)))

(defun flymake-elisp-config-config-p ()
  "Return non-nil if current buffer file is Emacs configuration file.
Each element of REGEXP-LIST, a regular expression, matches Emacs configuration
files."
  (let* ((file (buffer-file-name))
         (current-directory default-directory)
         (file-fullname (expand-file-name file current-directory))
         (regexp-list flymake-elisp-config-config-file-name-regexp-list))
    (seq-some
     (lambda (regexp)
       (string-match-p regexp file-fullname))
     regexp-list)))

;;;###autoload
(defun flymake-elisp-config-as-config ()
  "Current buffer file is regarded as Emacs configuration file by flymake.
`load-path' used by flymake is provided by
`flymake-elisp-config-get-load-path-config'."
  (interactive)
  (flymake-elisp-config-mode)
  (setq flymake-elisp-config-load-path-getter #'flymake-elisp-config-get-load-path-config))


;;; `load-path' getter for project maneged by `keg'

(defun flymake-elisp-config-get-load-path-keg ()
  "Get `load-path' for flymake in Emacs Lisp package file managed by `keg'."
  (append elisp-flymake-byte-compile-load-path
          (let ((default-directory (project-root (project-current))))
           (split-string
           (car (last (split-string (shell-command-to-string "keg load-path"))))
           (path-separator)))))

(defun flymake-elisp-config-keg-p ()
  "Return non-nil if current buffer is in the project managed by `keg'."
  (when-let* ((project (project-current))
              (root (project-root project)))
    (locate-file "Keg" (list root))))

;;;###autoload
(defun flymake-elisp-config-as-keg ()
  "Current buffer file is regarded as a `keg'-managed project by flymake.
`load-path' used by flymake is provided by
`flymake-elisp-config-get-load-path-keg'."
  (interactive)
  (flymake-elisp-config-mode)
  (setq flymake-elisp-config-load-path-getter #'flymake-elisp-config-get-load-path-keg))

(provide 'flymake-elisp-config)
;;; flymake-elisp-config.el ends here
