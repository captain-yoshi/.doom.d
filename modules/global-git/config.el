;;; global-git/config.el -*- lexical-binding: t; -*-
(require 'cl-lib)
(require 'subr-x)
(require 'tabulated-list)

(defvar my/global-git-buffer-name "*Global Git Status*")
(defvar my/global-git-max-processes 4)
(defvar my/global-git--generation 0)
(defvar my/global-git--pending nil)
(defvar my/global-git--active 0)
(defvar my/global-git--results nil)
(defvar my/global-git--expanded nil)
(defvar my/global-git--processes nil)

;; Remember whether Git reused a window or created a new one.
(defvar my/global-git--saved-windows (make-hash-table :test #'eq))

(defun my/global-git--projects ()
  "Return projects from the active workspace project set."
  (when my/active-workspace-project-set
    (or (cdr (assoc my/active-workspace-project-set
                    my/workspace-project-sets))
        (user-error "Unknown workspace project set: %s"
                    my/active-workspace-project-set))))

(defun my/global-git--parse (output)
  (let ((branch "-") (ahead 0) (behind 0)
        (staged 0) (modified 0) (untracked 0) files)
    (dolist (line (split-string output "\n" t))
      (cond
       ((string-prefix-p "# branch.head " line)
        (setq branch (substring line (length "# branch.head "))))
       ((string-match "^# branch.ab +\\+\\([0-9]+\\) -\\([0-9]+\\)" line)
        (setq ahead (string-to-number (match-string 1 line))
              behind (string-to-number (match-string 2 line))))
       ((string-prefix-p "? " line)
        (cl-incf untracked)
        (push (cons "?" (substring line 2)) files))
       ((or (string-prefix-p "1 " line) (string-prefix-p "2 " line))
        (let* ((fields (split-string line " " t))
               (xy (nth 1 fields))
               (path (car (last fields))))
          (when (and xy (= (length xy) 2))
            (unless (eq (aref xy 0) ?.) (cl-incf staged))
            (unless (eq (aref xy 1) ?.) (cl-incf modified))
            (push (cons xy path) files))))
       ((string-prefix-p "u " line)
        (cl-incf staged)
        (cl-incf modified)
        (push (cons "UU" (car (last (split-string line " " t)))) files))))
    (list :branch branch :ahead ahead :behind behind :staged staged
          :modified modified :untracked untracked :files (nreverse files))))

(defun my/global-git--color (value face)
  "Apply FACE to VALUE, dimming zero counts."
  (let ((text (format "%s" value)))
    (propertize text
                'face (if (equal text "0")
                          'shadow
                        face))))

(defun my/global-git--entries ()
  "Build colored rows for the Git dashboard."
  (let (entries)
    (dolist (name (my/global-git--projects))
      (let* ((data (alist-get name my/global-git--results nil nil #'equal))
             (state (cond
                     ((not data) "waiting")
                     ((eq data :error) "error")
                     ((zerop (+ (plist-get data :staged)
                                (plist-get data :modified)
                                (plist-get data :untracked)))
                      "clean")
                     (t "dirty")))
             (state-face
              (pcase state
                ("clean" 'success)
                ("dirty" 'warning)
                ("error" 'error)
                (_ 'shadow))))

        ;; Project summary.
        (push
         (list name
               (vector
                (concat
                 (if (member name my/global-git--expanded)
                     "▾ " "▸ ")
                 (propertize name
                             'face (if (equal state "dirty")
                                       'font-lock-warning-face
                                     'default)))

                (my/global-git--color
                 (if (listp data)
                     (plist-get data :branch) "-")
                 'font-lock-keyword-face)

                (my/global-git--color
                 (if (listp data) (plist-get data :staged) "-")
                 'success)

                (my/global-git--color
                 (if (listp data) (plist-get data :modified) "-")
                 'warning)

                (my/global-git--color
                 (if (listp data) (plist-get data :untracked) "-")
                 'font-lock-warning-face)

                (my/global-git--color
                 (if (listp data) (plist-get data :ahead) "-")
                 'font-lock-type-face)

                (my/global-git--color
                 (if (listp data) (plist-get data :behind) "-")
                 'error)

                (propertize state 'face state-face)))
         entries)

        ;; Expanded changed files.
        (when (and (listp data)
                   (member name my/global-git--expanded))
          (dolist (file (plist-get data :files))
            (let* ((status (car file))
                   (path (cdr file))
                   (face (cond
                          ((equal status "?") 'font-lock-warning-face)
                          ((string-match-p "D" status) 'error)
                          ((string-match-p "A" status) 'success)
                          (t 'warning))))
              (push
               (list (cons name path)
                     (vector
                      (concat "    "
                              (propertize status 'face face)
                              " "
                              (propertize path 'face 'shadow))
                      "" "" "" "" "" "" ""))
               entries))))))

    (nreverse entries)))

(defun my/global-git--render ()
  "Render the current results, preserving the selected row when possible."
  (when-let ((buffer (get-buffer my/global-git-buffer-name)))
    (with-current-buffer buffer
      (let ((id (ignore-errors (tabulated-list-get-id)))
            (inhibit-read-only t))
        (setq tabulated-list-entries (my/global-git--entries))
        (tabulated-list-print t)
        (when id
          (goto-char (point-min))
          (catch 'found
            (while (not (eobp))
              (when (equal (tabulated-list-get-id) id)
                (throw 'found t))
              (forward-line 1))))))))

(defun my/global-git--pump (generation)
  (while (and (= generation my/global-git--generation)
              my/global-git--pending
              (< my/global-git--active my/global-git-max-processes))
    (let* ((name (pop my/global-git--pending))
           (root (file-name-as-directory
                  (expand-file-name name my/workspace-project-root)))
           (output (generate-new-buffer " *global-git-output*")))
      (if (not (file-directory-p root))
          (progn
            (push (cons name :error) my/global-git--results)
            (kill-buffer output)
            (my/global-git--render))
        (condition-case nil
            (let ((process
                   (make-process
                    :name (concat "global-git-" name)
                    :buffer output :noquery t
                    :command (list "git" "-C" root "status" "--porcelain=v2"
                                   "--branch" "--untracked-files=normal")
                    :sentinel
                    (lambda (proc _event)
                      (when (memq (process-status proc) '(exit signal))
                        (setq my/global-git--processes
                              (delq proc my/global-git--processes))
                        (when (= generation my/global-git--generation)
                          (cl-decf my/global-git--active)
                          (push (cons name
                                      (if (= (process-exit-status proc) 0)
                                          (my/global-git--parse
                                           (with-current-buffer (process-buffer proc)
                                             (buffer-string)))
                                        :error))
                                my/global-git--results)
                          (my/global-git--render))
                        (when (buffer-live-p (process-buffer proc))
                          (kill-buffer (process-buffer proc)))
                        (when (= generation my/global-git--generation)
                          (my/global-git--pump generation)))))))
              (push process my/global-git--processes)
              (cl-incf my/global-git--active))
          (error
           (kill-buffer output)
           (push (cons name :error) my/global-git--results)
           (my/global-git--render)))))))

(defun my/global-git-refresh ()
  "Refresh all project statuses without blocking the editor."
  (interactive)
  (cl-incf my/global-git--generation)
  (dolist (proc my/global-git--processes)
    (when (process-live-p proc) (delete-process proc)))
  (setq my/global-git--processes nil
        my/global-git--active 0
        my/global-git--results nil
        my/global-git--pending (copy-sequence (my/global-git--projects)))
  (my/global-git--render)
  (my/global-git--pump my/global-git--generation))

(defun my/global-git-visit ()
  "Expand a project, or open its changed file."
  (interactive)
  (let ((id (tabulated-list-get-id)))
    (cond
     ((consp id)
      (find-file (expand-file-name (cdr id)
                                   (expand-file-name (car id) my/workspace-project-root))))
     ((stringp id)
      (if (member id my/global-git--expanded)
          (setq my/global-git--expanded (delete id my/global-git--expanded))
        (push id my/global-git--expanded))
      (my/global-git--render)))))

(defun my/global-git-magit ()
  "Open Magit for the selected project."
  (interactive)
  (let* ((id (tabulated-list-get-id))
         (name (if (consp id) (car id) id)))
    (unless name (user-error "No project selected"))
    (my/magit-status-smart (expand-file-name name my/workspace-project-root))))

(defun my/global-git-close ()
  "Close Global Git, restore the layout and return focus."
  (interactive)
  (when-let ((win (get-buffer-window my/global-git-buffer-name nil)))
    (let* ((saved (gethash win my/global-git--saved-windows))
           (source (pcase (car-safe saved)
                     ('created (nth 1 saved))
                     ('restore (nth 5 saved)))))
      (remhash win my/global-git--saved-windows)

      (pcase (car-safe saved)
        ;; Git created a window: remove it entirely.
        ('created
         (when (not (one-window-p t))
           (delete-window win)))

        ;; Git reused a window: restore its original contents.
        ('restore
         (set-window-dedicated-p win nil)
         (set-window-buffer win (nth 1 saved))
         (set-window-point win (nth 2 saved))
         (set-window-start win (nth 3 saved) t)
         (set-window-dedicated-p win (nth 4 saved)))

        ;; Fallback.
        (_
         (quit-window nil win)))

      ;; Return focus to the window active before Global Git opened.
      (when (window-live-p source)
        (select-window source)))))

(define-derived-mode my/global-git-mode tabulated-list-mode "Global-Git"
  "Major mode for the global Git dashboard."
  (setq tabulated-list-format
        [("Project / file" 34 t) ("Branch" 19 t)
         ("S" 3 nil) ("M" 3 nil) ("?" 3 nil)
         ("↑" 3 nil) ("↓" 3 nil) ("State" 8 nil)])
  (setq tabulated-list-padding 1)
  (setq-local revert-buffer-function (lambda (&rest _) (my/global-git-refresh)))
  (tabulated-list-init-header))

(map! :map my/global-git-mode-map :n "g" #'my/global-git-refresh
      :n "RET" #'my/global-git-visit
      :n "m" #'my/global-git-magit
      :n "q" #'my/global-git-close)

(defun my/global-git--rightmost-window ()
  "Find the uppermost ordinary window in the rightmost column."
  (let* ((windows (cl-remove-if
                   (lambda (w) (window-parameter w 'window-side))
                   (window-list nil 'nomini)))
         (max-left (apply #'max (mapcar (lambda (w) (nth 0 (window-edges w)))
                                        windows))))
    (car (sort (cl-remove-if-not
                (lambda (w) (= (nth 0 (window-edges w)) max-left))
                windows)
               (lambda (a b)
                 (< (nth 1 (window-edges a))
                    (nth 1 (window-edges b))))))))

(defun my/global-git-toggle ()
  "Show Git in the rightmost window; toggle again to restore it."
  (interactive)
  (unless (or (get-buffer-window my/global-git-buffer-name nil)
              my/active-workspace-project-set)
    (user-error "No workspace project set loaded. Use SPC TAB p 1 first"))
  (if (get-buffer-window my/global-git-buffer-name nil)
      (my/global-git-close)
    (let* ((source (selected-window))
           (buffer (get-buffer-create my/global-git-buffer-name))
           (ordinary (cl-remove-if
                      (lambda (w) (window-parameter w 'window-side))
                      (window-list nil 'nomini)))
           (right (my/global-git--rightmost-window))
           ;; If all windows share a left edge, there is no right column.
           (left-edge (apply #'min (mapcar
                                    (lambda (w) (car (window-edges w)))
                                    ordinary)))
           (reuse (> (car (window-edges right)) left-edge))
           (target (if reuse right (split-window right nil 'right))))
      ;; Only save an existing window's contents. New windows close on q.
      (puthash target
               (if reuse
                   (list 'restore
                         (window-buffer target)
                         (window-point target)
                         (window-start target)
                         (window-dedicated-p target)
                         source)
                 (list 'created source))
               my/global-git--saved-windows)
      (with-current-buffer buffer
        (unless (derived-mode-p 'my/global-git-mode)
          (my/global-git-mode)))
      (set-window-dedicated-p target nil)
      (set-window-buffer target buffer)
      (select-window target)
      (my/global-git-refresh))))

;;; ============================================================
;;; Auto-refresh when returning to Global Git
;;; ============================================================

(defvar my/global-git--last-workspace nil
  "Previously active workspace.")

(defun my/global-git--refresh-on-workspace-switch (&rest _)
  "Refresh Git when switching to a workspace displaying the dashboard."
  (let ((workspace (and (boundp 'persp-mode)
                        persp-mode
                        (get-current-persp))))
    (when (and workspace
               (not (eq workspace my/global-git--last-workspace)))
      (setq my/global-git--last-workspace workspace)
      (when (get-buffer-window my/global-git-buffer-name nil)
        (my/global-git-refresh)))))

(after! persp-mode
  (add-hook 'persp-activated-functions
            #'my/global-git--refresh-on-workspace-switch))


(map! :leader
      (:prefix ("g" . "git")
       :desc "Global Git Status" "p" #'my/global-git-toggle))
