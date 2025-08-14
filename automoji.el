;;; automoji.el --- Discord-like emoji completion -*- lexical-binding: t -*-

;; Copyright (C) 2025 Dev380

;; Author: Dev380
;; Maintainer: Dev380
;; Created: 2025
;; Version: 2.3
;; Package-Requires: ((emacs "29.1"))
;; URL: https://github.com/Dev380/automoji-el
;; Keywords: completion, abbrev, convenience, text

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; This package provides emoji completion with shortcodes, kind of like `cape-emoji'
;; but prioritizing discord and github emoji shortcodes when possible and including
;; a larger list of emojis.

;;; Code:

(defvar automoji--data nil
  "Data mapping shortcodes to emojis that will be lazy-loaded.")

(defun automoji--load-data ()
  "Load the emoji hashtable from disk."
  (let ((current-file
         (if load-in-progress
             load-file-name
           (locate-library "automoji.el"))))
    (setq automoji--data
          (car
           (with-temp-buffer
             (insert-file-contents
              (expand-file-name
               "generated.data"
               (file-name-parent-directory current-file)))
             (read-from-string (buffer-string))))))
  automoji--data)

(defun automoji--annotation (shortcode)
  "Gets completion annotation based on the SHORTCODE's emoji."
  ;; Implementation copied from cape
  (when-let ((char (gethash shortcode automoji--data)))
    (format (if (stringp char)
                " %s "
              " %c ")
            char)))

;;;###autoload
(defun automoji-capf (&optional interactive)
  "A completion at point function for emoji.
If INTERACTIVE is nil the function acts like a capf."
  (interactive (list t))
  (if interactive
      (let ((completion-at-point-functions #'automoji-capf))
        (or (completion-at-point)
            (user-error "automoji-capf: No completions")))
    (let ((bounds (bounds-of-thing-at-point 'symbol)))
      (when bounds
        (list
         (if (= (char-after (car bounds)) ?:)
             (car bounds)
           (- (car bounds) 1))
         (cdr bounds) (or automoji--data (automoji--load-data))
         :exclusive 'no
         :company-kind (lambda (_) 'text)
         :annotation-function #'automoji--annotation
         :company-docsig #'identity
         :company-doc-buffer #'ignore
         :exit-function
         (lambda (shortcode status)
           (when (string= status "finished")
             (delete-char (- (length shortcode)))
             (insert (gethash shortcode automoji--data)))))))))

(provide 'automoji)
;;; automoji.el ends here
