;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


;; ;;; --- Remote dev: sshfs + TRAMP hybrid setup ---

;; (defvar my/remote-hosts-config "~/.config/remote-hosts.conf")

;; (defun my/load-remote-hosts ()
;;   "Parse config file into a list of mappings."
;;   (when (file-exists-p my/remote-hosts-config)
;;     (with-temp-buffer
;;       (insert-file-contents my/remote-hosts-config)
;;       (let (hosts)
;;         (dolist (line (split-string (buffer-string) "\n" t))
;;           (unless (string-match-p "^#" line)
;;             (let* ((parts (split-string line "[ \t]+" t))
;;                    (name (nth 0 parts))
;;                    (remote (nth 1 parts))
;;                    (remote-path (file-name-as-directory (nth 2 parts)))
;;                    (local (file-name-as-directory
;;                            (expand-file-name (nth 3 parts)))))
;;               (push (list name remote remote-path local) hosts))))
;;         hosts))))

;; (defvar my/remote-hosts (my/load-remote-hosts))

;; ;;; --- Normalize TRAMP paths (fix ~ issues globally) ---

;; (defun my/normalize-tramp-path (path)
;;   "Fix TRAMP paths using ~ → absolute home."
;;   (if (and (stringp path)
;;            (string-match "^/ssh:\\([^:]+\\):~/" path))
;;       (let* ((remote (match-string 1 path))
;;              (user (car (split-string remote "@")))
;;              (fixed (concat "/ssh:" remote ":/home/" user "/")))
;;         (replace-regexp-in-string
;;          "^/ssh:[^:]+:~/"
;;          fixed
;;          path))
;;     path))

;; ;; Apply globally (fix VC, Projectile, etc.)
;; ;; (advice-add 'expand-file-name :filter-return #'my/normalize-tramp-path)
;; ;; (advice-add 'file-name-directory :filter-return #'my/normalize-tramp-path)

;; ;;; --- sshfs → TRAMP (open files via TRAMP) ---

;; (defun my/mount-to-tramp (path)
;;   "Convert sshfs path to TRAMP path."
;;   (let ((path (expand-file-name path)))
;;     (catch 'result
;;       (dolist (host my/remote-hosts)
;;         (let* ((remote (nth 1 host))
;;                (remote-path (nth 2 host))
;;                (local (nth 3 host)))
;;           (when (string-prefix-p local path)
;;             (let ((relative (string-remove-prefix local path)))
;;               (throw 'result
;;                      (concat "/ssh:" remote ":" remote-path relative))))))
;;       path)))

;; (defun my/find-file-smart (orig-fn &rest args)
;;   "Automatically open sshfs files via TRAMP."
;;   (let* ((file (car args))
;;          (normalized (and file (my/normalize-tramp-path file)))
;;          (mapped (and normalized (my/mount-to-tramp normalized))))
;;     (apply orig-fn (list (or mapped normalized file)))))

;; (advice-add 'find-file :around #'my/find-file-smart)

;; ;;; --- TRAMP → sshfs (search locally via sshfs) ---

;; (defun my/tramp-to-mount (path)
;;   "Convert TRAMP path to sshfs mount path."
;;   (when (file-remote-p path)
;;     (let ((path (my/normalize-tramp-path path)))
;;       (catch 'result
;;         (dolist (host my/remote-hosts)
;;           (let* ((remote (nth 1 host))
;;                  (remote-path (nth 2 host))
;;                  (local (nth 3 host)))
;;             (when (string-match
;;                    (concat "^/ssh:" (regexp-quote remote) ":" (regexp-quote remote-path))
;;                    path)
;;               (let ((relative (string-remove-prefix
;;                                (concat "/ssh:" remote ":" remote-path)
;;                                path)))
;;                 (throw 'result (concat local relative))))))
;;         nil))))

;; (defun my/project-root-smart ()
;;   "Use sshfs path for search even when in TRAMP."
;;   (or (my/tramp-to-mount default-directory)
;;       default-directory))

;; ;;; --- Smart search (always local ripgrep) ---

;; (defun my/search-project-smart ()
;;   (interactive)
;;   (let ((dir (my/project-root-smart)))
;;     (message "SEARCH DIR: %s" dir)
;;     (let ((default-directory dir))
;;       (+default/search-project))))

;; (defun my/search-symbol-smart ()
;;   "Search symbol using sshfs when in TRAMP."
;;   (interactive)
;;   (let ((default-directory (my/project-root-smart)))
;;     (call-interactively #'+default/search-project-for-symbol-at-point)))

;; (map! :leader
;;       :desc "Smart project search" "/" #'my/search-project-smart
;;       :desc "Smart search symbol" "*" #'my/search-symbol-smart)

;;; ============================================================
;;; Remote dev: sshfs-first workflow (NO TRAMP by default)
;;; ============================================================

(defvar my/remote-hosts-config "~/.config/remote-hosts.conf"
  "Config file describing sshfs mounts.")

(defun my/load-remote-hosts ()
  "Parse config file into a list of mappings:
(name remote remote-path local-path)."
  (when (file-exists-p my/remote-hosts-config)
    (with-temp-buffer
      (insert-file-contents my/remote-hosts-config)
      (let (hosts)
        (dolist (line (split-string (buffer-string) "\n" t))
          (unless (or (string-match-p "^#" line)
                      (string-blank-p line))
            (pcase-let* ((`(,name ,remote ,remote-path ,local)
                          (split-string line "[ \t]+" t)))
              (push (list name
                          remote
                          (file-name-as-directory remote-path)
                          (file-name-as-directory (expand-file-name local)))
                    hosts))))
        hosts))))

(defvar my/remote-hosts (my/load-remote-hosts)
  "List of configured sshfs hosts.")

(defun my/reload-remote-hosts ()
  "Reload sshfs host config."
  (interactive)
  (setq my/remote-hosts (my/load-remote-hosts))
  (message "Reloaded sshfs hosts"))

;;; ============================================================
;;; TRAMP → sshfs (fallback only)
;;; ============================================================

(defun my/tramp-to-mount (path)
  "Convert TRAMP PATH to sshfs mount path."
  (when (and path (file-remote-p path))
    (catch 'result
      (dolist (host my/remote-hosts)
        (pcase-let ((`(,_ ,remote ,remote-path ,local) host))
          (when (string-match
                 (concat "^/ssh:" (regexp-quote remote) ":" (regexp-quote remote-path))
                 path)
            (let ((relative (string-remove-prefix
                             (concat "/ssh:" remote ":" remote-path)
                             path)))
              (throw 'result (concat local relative))))))
      nil)))

(defun my/project-root-smart ()
  "Prefer sshfs path if current buffer is TRAMP."
  (or (my/tramp-to-mount default-directory)
      default-directory))

;;; ============================================================
;;; Smart search (always LOCAL ripgrep via sshfs)
;;; ============================================================

(defun my/search-project-smart ()
  "Search project using local ripgrep (sshfs-aware)."
  (interactive)
  (let ((default-directory (my/project-root-smart)))
    (+default/search-project)))

(defun my/search-symbol-smart ()
  "Search symbol using local ripgrep (sshfs-aware)."
  (interactive)
  (let ((default-directory (my/project-root-smart)))
    (call-interactively #'+default/search-project-for-symbol-at-point)))

(map! :leader
      :desc "Smart project search" "/" #'my/search-project-smart
      :desc "Smart search symbol" "*" #'my/search-symbol-smart)

;;; ============================================================
;;; Projectile optimizations (CRITICAL for sshfs)
;;; ============================================================

(after! projectile
  ;; Use external tools (rg/fd) instead of Emacs scanning
  (setq projectile-indexing-method 'alien)

  ;; Enable caching (reduces sshfs stat calls)
  (setq projectile-enable-caching t)

  ;; Ignore heavy directories
  (setq projectile-globally-ignored-directories
        '(".git" "node_modules" "build" "dist" ".cache"
          ".venv" "__pycache__" ".mypy_cache" ".pytest_cache"))

  ;; Optional: ignore large files
  (setq projectile-globally-ignored-file-suffixes
        '(".o" ".so" ".a" ".pyc" ".class")))

;;; ============================================================
;;; Ripgrep tuning (faster over sshfs)
;;; ============================================================

(after! counsel
  (setq counsel-rg-base-command
        "rg -M 240 --with-filename --no-heading --line-number --color never %s ."))

;;; ============================================================
;;; LSP optimizations (VERY IMPORTANT for sshfs)
;;; ============================================================

(after! lsp-mode
  ;; Disable file watchers (huge sshfs slowdown otherwise)
  (setq lsp-enable-file-watchers nil)

  ;; Prevent too many tracked files
  (setq lsp-file-watch-threshold 1000)

  ;; Optional: reduce overhead
  (setq lsp-idle-delay 0.5)
  (setq lsp-log-io nil))

;;; ============================================================
;;; Quality of life
;;; ============================================================

;; Reload hosts easily
(map! :leader
      :desc "Reload sshfs hosts"
      "o r" #'my/reload-remote-hosts)

;; Debug helper
(defun my/print-remote-hosts ()
  (interactive)
  (message "%S" my/remote-hosts))

;;; ============================================================
;;; Optional: TRAMP tuning (only for fallback use)
;;; ============================================================

(after! tramp
  ;; Faster SSH connection reuse
  (setq tramp-ssh-controlmaster-options
        "-o ControlMaster=auto -o ControlPersist=10m")

  ;; Reduce TRAMP verbosity
  (setq tramp-verbose 1))

;; RasberryPi Pico
(load! "modules/pico/config")
(load! "modules/pico/keybinds")


;; Ensure Emacs uses the same environment variables as your shell
(use-package! exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))


;;; ============================================================
;;; CMake / compile_commands auto-setup
;;; ============================================================

(after! projectile

  ;; 🔹 Robust project root detection
  (defun my/project-root ()
    "Robust project root detection."
    (or (ignore-errors (projectile-project-root))
        (locate-dominating-file default-directory "CMakeLists.txt")
        default-directory))

  ;; 🔹 Main function
  (defun my/cmake-ensure-compile-commands ()
    "Ensure compile_commands.json exists and is up-to-date."
    (let* ((root (my/project-root))
           (cmake-file (expand-file-name "CMakeLists.txt" root))
           (cc (expand-file-name "compile_commands.json" root))
           (buf "*cmake-configure*"))

      (when (file-exists-p cmake-file)
        (let ((default-directory root))
          (when (or (not (file-exists-p cc))
                    (file-newer-than-file-p cmake-file cc))

            ;; 🔔 UX message
            (message "🔧 CMake: generating compile_commands.json...")

            ;; Clear buffer
            (with-current-buffer (get-buffer-create buf)
              (erase-buffer))

            ;; Run CMake
            (let ((exit-code
                   (call-process-shell-command
                    "cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ."
                    nil buf t)))

              (if (= exit-code 0)
                  (progn
                    ;; 🔗 Symlink to root (clangd expects it here)
                    (call-process-shell-command
                     "ln -sf build/compile_commands.json ." nil 0)

                    (message "✅ CMake: compile_commands.json ready")

                    ;; 🔥 Reload LSP so clangd picks it up
                    (when (and (bound-and-true-p lsp-mode)
                               (lsp-workspaces))
                      (lsp-workspace-restart (car (lsp-workspaces)))))

                ;; ❌ Failure
                (message "❌ CMake failed — see %s" buf)
                (display-buffer buf))))))))

  ;; 🔹 Run when switching project
  (add-hook 'projectile-after-switch-project-hook
            #'my/cmake-ensure-compile-commands)

  ;; 🔹 Re-run when CMakeLists changes
  (add-hook 'after-save-hook
            (lambda ()
              (when (and buffer-file-name
                         (string-match-p "CMakeLists.txt$" buffer-file-name))
                (my/cmake-ensure-compile-commands)))))


;;; --- Project detection ---

;; (defun my/is-pico-project ()
;;   "Detect if current project uses pico-sdk."
;;   (let ((root (or (ignore-errors (projectile-project-root))
;;                   default-directory)))
;;     (when (and root (file-exists-p (expand-file-name "CMakeLists.txt" root)))
;;       (with-temp-buffer
;;         (insert-file-contents (expand-file-name "CMakeLists.txt" root))
;;         (string-match-p "pico_sdk_init" (buffer-string))))))

;; (defun my/project-uses-arm-gcc ()
;;   "Detect ARM toolchain from compile_commands.json."
;;   (let* ((root (or (ignore-errors (projectile-project-root))
;;                    default-directory))
;;          (cc (expand-file-name "compile_commands.json" root)))
;;     (when (file-exists-p cc)
;;       (with-temp-buffer
;;         (insert-file-contents cc)
;;         (string-match-p "arm-none-eabi" (buffer-string))))))

;; (defun my/setup-clangd-for-project ()
;;   "Configure clangd per project."
;;   (let ((is-arm
;;          (or (my/is-pico-project)
;;              (my/project-uses-arm-gcc))))
;;     (message "🔍 clangd setup: is-arm=%s" is-arm)
;;     (when is-arm
;;       (let ((driver (string-trim
;;                      (shell-command-to-string "which arm-none-eabi-g++"))))
;;         (message "🔧 Using ARM driver: %s" driver)
;;         (setq-local lsp-clients-clangd-args
;;                     (list (format "--query-driver=%s" driver)))))))

;; (add-hook 'lsp-before-initialize-hook #'my/setup-clangd-for-project)

(setq lsp-clients-clangd-args '("--query-driver=**"))

;;; ============================================================
;;; Magit remote: auto-detect host from mount name
;;; ============================================================
(defvar my/remote-hosts-file "~/.config/remote-hosts.conf")

(defun my/parse-remote-hosts ()
  "Parse remote-hosts.conf into a list of (mount userhost remotepath)."
  (when (file-exists-p my/remote-hosts-file)
    (with-temp-buffer
      (insert-file-contents my/remote-hosts-file)
      (cl-loop for line in (split-string (buffer-string) "\n" t)
               unless (string-match-p "^\\s-*#" line)
               collect
               (let* ((parts (split-string line " " t))
                      (name (nth 0 parts))
                      (userhost (nth 1 parts))
                      (remotepath (nth 2 parts))
                      (mount (expand-file-name (nth 3 parts))))
                 (list mount userhost remotepath))))))

(defun my/find-tramp-path (dir)
  "Return TRAMP path if DIR is inside an SSHFS mount."
  (let ((hosts (my/parse-remote-hosts)))
    (cl-loop for (mount userhost remotepath) in hosts
             when (string-prefix-p mount dir)
             return
             (let* ((relative (string-remove-prefix mount dir))
                    (tramp-path (format "/ssh:%s:%s%s"
                                        userhost
                                        remotepath
                                        relative)

                                ))
               tramp-path))))

(defun my/magit-status-smart (&optional directory)
  "Open Magit, switching SSHFS paths to TRAMP automatically."
  (interactive)
  (let* ((dir (or directory default-directory))
         (tramp-path (my/find-tramp-path dir))
         (final-dir (or tramp-path dir)))

    (let ((git-root (magit-toplevel final-dir)))
      (if git-root
          (progn
            (when tramp-path
              (message "Magit via TRAMP: %s" tramp-path))
            (magit-status git-root))
        (user-error "Not inside a Git repository: %s" final-dir)))))

;; Replace Magit binding
(map! :leader
      :desc "Magit (smart SSHFS → TRAMP)"
      "g g" #'my/magit-status-smart)


;; (defun my/ensure-remote-git-config (dir)
;;   "Ensure git user.name and user.email are set on remote hosts for DIR."
;;   (when (file-remote-p dir)
;;     (let ((default-directory dir))
;;       (let ((config (shell-command-to-string "git config --global --list 2>/dev/null")))
;;         (unless (and (string-match "user.name=" config)
;;                      (string-match "user.email=" config))
;;           (message "Setting remote git identity...")
;;           (shell-command
;;            "git config --global user.name 'Captain Yoshi' && git config --global user.email 'captain.yoshisaur@gmail.com'"))))))

(defun my/tramp-git-identity-env ()
  "Set git identity when working over TRAMP."
  (when (file-remote-p default-directory)
    (setenv "GIT_AUTHOR_NAME" "Captain Yoshi")
    (setenv "GIT_AUTHOR_EMAIL" "captain.yoshisaur@gmail.com")
    (setenv "GIT_COMMITTER_NAME" "Captain Yoshi")
    (setenv "GIT_COMMITTER_EMAIL" "captain.yoshisaur@gmail.com")))

(add-hook 'find-file-hook #'my/tramp-git-identity-env)



;; C++: use clangd diagnostics only
(after! flycheck
  (setq-default flycheck-disabled-checkers
                '(c/c++-gcc
                  c/c++-clang
                  c/c++-cppcheck)))

;; disable lsp headerline breadcrumb
(remove-hook 'lsp-mode-hook #'lsp-headerline-breadcrumb-mode)


;; -------------------------------
;; Embark -> SPC A
;; -------------------------------

(map! :leader
      :n "A" #'embark-act)

;; Remove Doom's SPC a binding
(define-key doom-leader-map (kbd "a") nil)

;; Create AI prefix
(define-prefix-command 'my/ai-map)
(define-key doom-leader-map (kbd "a") 'my/ai-map)


;; -------------------------------
;; Copilot
;; -------------------------------

(use-package! copilot
  :hook (prog-mode . copilot-mode)

  :bind (:map copilot-completion-map
              ("<tab>" . copilot-accept-completion)
              ("TAB" . copilot-accept-completion)))


;; -------------------------------
;; Claude Code
;; -------------------------------

(use-package! claude-code-ide
  :commands (claude-code-ide-menu)
  :init
  ;; Add key immediately, autoload command when used
  (define-key my/ai-map (kbd "a") #'claude-code-ide-menu)

  :config
  (claude-code-ide-emacs-tools-setup))


;; -------------------------------
;; GPTel
;; -------------------------------

(use-package! gptel
  :commands (gptel gptel-menu)
  :init
  (define-key my/ai-map (kbd "c") #'gptel)
  (define-key my/ai-map (kbd "m") #'gptel-menu)

  :config
  (setq gptel-backend
        (gptel-make-gh-copilot "Copilot"))

  (setq gptel-model 'claude-sonnet-4.6))


;; -------------------------------
;; ECA
;; -------------------------------

(use-package! eca
  :defer t

  :init
  (define-key my/ai-map (kbd "e") #'eca)
  (define-key my/ai-map (kbd "E") #'eca-chat-new))


;; -------------------------------
;; Pre-commit
;; -------------------------------

(defun my/pre-commit-run-all ()
  "Run pre-commit on the entire repository."
  (interactive)
  (compile "pre-commit run --all-files"))

(map! :leader
      (:prefix ("c" . "code")
       :desc "Pre-commit (all files)"
       "P" #'my/pre-commit-run-all))
