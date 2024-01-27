;;; sane-modules.el --- Manage and load custom Emacs modules efficiently -*- lexical-binding: t; -*-

;; Author: Leslie S. Russell
;; Version: 1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: convenience, modules
;; URL:

;;; Commentary:

;; The `sane-modules` package provides an organized way to manage and load custom Emacs modules.
;; It allows users to define a base directory for modules, specify a list of modules to load,
;; and automate the loading process with optional timing reports. This package is especially
;; useful for Emacs users who have a large number of custom configurations or modules and
;; want to maintain a clean and manageable Emacs setup.

;; Features:
;; - Define a base directory for all your custom modules.
;; - Specify which modules to load with a simple list.
;; - Automatically load configuration files from each module directory.
;; - Option to report loading times for performance analysis.

;; Usage:
;; To use `sane-modules`, configure the base directory and module list in your Emacs init file:
;;
;; (setq sane-module-base-directory "~/path/to/your/modules/")
;; (setq sane-module-module-list '(module1 module2 module3))
;;
;; Then, load the modules with:
;;
;; (sane-modules-load-modules sane-module-base-directory sane-module-module-list)

;; For more detailed instructions and examples, see the function documentation below.

;;; Code:

;; Group definition for customization
(defgroup sane-modules nil
  "Customization options for sane-modules package."
  :group 'convenience
  :prefix "sane-module-")

(defcustom sane-module-base-directory "~/sane-modules/"
  "Base directory for SANE modules."
  :type 'string
  :group 'sane-modules)

(defcustom sane-module-module-list '()
  "List of SANE modules to load."
  :type '(repeat symbol)
  :group 'sane-modules)

(defcustom sane-module-config-list '()
  "List of SANE module configurations."
  :type '(repeat string)
  :group 'sane-modules)

(defcustom sane-module-template
  (concat ";;; %s.el --- Description of the package -*- lexical-binding: t; -*-\n\n"
          ";;; Commentary:\n"
          ";; This file contains the '%s' package with functionalities:\n"
          ";; - ...\n\n"
          ";;; Code:\n\n"
          "(use-package %s\n"
          "  :ensure t\n"
          "  ;; Add your configuration here\n\n"
          "  )\n\n"
          ";;; Provide\n(provide '%s)\n\n"
          ";;; %s.el ends here\n")
  "Module template string."
  :type 'string
  :group 'sane-modules)

(require 'cl-lib)

(defun sane-create-project-with-template ()
  "Create a new project directory, and a config.el file with a template."
  (interactive)
  (let* ((dir (read-string "Enter the directory path: "))
         (project-name (read-string "Enter the project name: "))
         (full-path (expand-file-name (concat sane-module-base-directory dir "/" project-name))))
    (message full-path)  ; Display the full path in the minibuffer
    (unless (file-exists-p full-path)
      (make-directory full-path t))
    (let ((config-file (concat full-path "/config.el")))
      (find-file config-file)
      (insert (sane-generate-elisp-template project-name))
      (save-buffer))))

(defun sane-generate-elisp-template (name)
  "Generate a template for an Emacs Lisp file.
   NAME is the name of the package to be used in the template."
  (format sane-module-template name name name name name))

;;;###autoload
(defun sane-modules-expand-paths (base-directory module-list)
  "Expand each symbol in MODULE-LIST to a subdirectory path within BASE-DIRECTORY.
Validate the existence of each path and return a list of the valid paths."
  (cl-loop for module in module-list
           for subdirectory = (expand-file-name (symbol-name module) base-directory)
           when (file-directory-p subdirectory)
           collect subdirectory))

;;;###autoload
(defun sane-modules-find-config-files (directory-list)
  "Find 'config.el' files within each directory in DIRECTORY-LIST.
Validate the existence of the file in each directory and return a list
of fully expanded file paths for the valid 'config.el' files."
  (let ((valid-paths '()))
    (dolist (directory directory-list valid-paths)
      (let ((config-file (expand-file-name "config.el" directory)))
        (when (file-exists-p config-file)
          (push config-file valid-paths))))))

(defun sane-modules-load-files (file-list timing-flag)
  "Load files from FILE-LIST.
Validate the existence of each file and load it. If TIMING-FLAG is non-nil,
report the load time for each file; otherwise, load the file without reporting load times."
  (let ((loaded-files '()))
    (cl-loop for file in file-list
             unless (file-exists-p file)
             do (message "File does not exist: %s" file)
             else do (if timing-flag
                         (let ((load-time (benchmark-run (load file))))
                           (message "Loaded file: %s, Load time: %.6f seconds" file (car load-time)))
                       (load file))
             finally return (nreverse loaded-files))))

;;;###autoload
(defun sane-modules-load-modules (base-directory module-list &optional timing-flag)
  "Load configuration files for modules in MODULE-LIST under BASE-DIRECTORY.
If TIMING-FLAG is non-nil, report the load time for each file; otherwise,
load the file without reporting load times."
  ;; (setq sane-module-paths (sane-modules-expand-paths base-directory module-list) timing-flag)
  ;; (setq sane-module-configs (sane-modules-find-config-files sane-module-paths))
  ;; (sane-modules-load-files sane-module-configs timing-flag)
  (sane-modules-load-files
   (sane-modules-find-config-files
    (sane-modules-expand-paths base-directory module-list)) timing-flag))

(provide 'sane-modules)
;;; sane-modules.el ends here
