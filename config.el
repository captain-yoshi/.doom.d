;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "monospace" :size 14))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; disable ref counts -> slow in c++ and annoying
;; https://emacs-lsp.github.io/lsp-mode/tutorials/how-to-turn-off/
(setq lsp-lens-enable nil)

;; Disable autoformatting onsave in nxml-mode.
;; https://discord.com/channels/406534637242810369/1343412176920121445/1343433693980790794
;; (add-to-list '+format-on-save-disabled-modes 'nxml-mode)

;; Use xmlindent formatter
;; https://discord.com/channels/406534637242810369/1343412176920121445/1343640100311007336
(after! nxml-mode
  (set-formatter! 'xmlindent '("xmlindent" "-l" "80" "-i" "2") :modes '(nxml-mode)))

;;(add-hook! 'burly-open-bookmark #'eshell-bookmark-setup)
;;(after! eshell (eshell-bookmark-setup))

;;(use-package! eshell-bookmark
;;  :after eshell
;;  :config
;;  (add-hook! 'eshell-mode-hook #'eshell-bookmark-setup))

;; Add ability to bookmark eshell
(eshell-bookmark-setup)
(add-hook! 'eshell-mode-hook #'eshell-bookmark-setup)

;; Specify python debugger
(after! dap-python
  (setq dap-python-executable "python3"
        dap-python-debugger 'debugpy))

;; https://emacs.stackexchange.com/a/27855
(defun tv/increment-number-in-file-name (name)
  (with-temp-buffer
    (insert name)
    (search-backward "." nil t)
    (re-search-backward "[0-9]+" nil t)
    ;(skip-chars-forward "0") ;; Would preserve 0s
    (if (looking-at "[0123456789]+")
        (replace-match (number-to-string (1+ (string-to-number (match-string 0)))))
      (insert "-1"))
    (buffer-string)))

(defun write-file-increment ()
  (interactive)
  (write-file (tv/increment-number-in-file-name (buffer-file-name))))

;; https://stackoverflow.com/a/2906371
(defun python-send-buffer-with-my-args (args)
  (interactive "sPython arguments: ")
  (let ((source-buffer (current-buffer)))
    (with-temp-buffer
      (insert "import sys; sys.argv = '''" args "'''.split()\n")
      (insert-buffer-substring source-buffer)
      (python-shell-send-buffer))))

(global-set-key "\C-c\C-a" 'python-send-buffer-with-my-args)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.
