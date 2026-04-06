;;; pico/config.el --- Raspberry Pi Pico full workflow -*- lexical-binding: t; -*-

;;; -----------------------------
;;; Dependencies
;;; -----------------------------

(require 'projectile)

;;; -----------------------------
;;; Detection
;;; -----------------------------

(defun pico/port ()
  "Return Pico serial port."
  (or (car (file-expand-wildcards "/dev/serial/by-id/*Raspberry*"))
      (car (file-expand-wildcards "/dev/ttyACM*"))))

(defun pico/ensure-port ()
  (or (pico/port)
      (error "❌ Pico not detected")))

(defun pico/mount-path ()
  "Return Pico mass storage mount (BOOTSEL mode)."
  (car (file-expand-wildcards "/media/*/RPI-RP2")))

;;; -----------------------------
;;; MicroPython
;;; -----------------------------

(defun pico/flash-micropython ()
  "Flash MicroPython UF2 (BOOTSEL mode required)."
  (interactive)
  (let* ((mount (pico/mount-path))
         (uf2 "~/ws/tools/rpi/pico/RPI_PICO-20251209-v1.27.0.uf2"))

    ;; Check firmware exists
    (unless (file-exists-p (expand-file-name uf2))
      (error "❌ MicroPython UF2 not found at: %s" uf2))

    ;; Check Pico is in BOOTSEL mode
    (unless mount
      (error "❌ Pico not in BOOTSEL mode (RPI-RP2 not mounted)"))

    ;; Flash
    (compile
     (format "cp %s %s/"
             (shell-quote-argument (expand-file-name uf2))
             mount))))

(defun pico/upload-python ()
  "Upload current buffer as main.py."
  (interactive)
  (let ((port (pico/ensure-port)))
    (save-buffer)
    (compile
     (format "mpremote connect %s fs cp %s :main.py"
             port
             (shell-quote-argument (buffer-file-name))))))

(defun pico/run-python ()
  "Run main.py on Pico."
  (interactive)
  (compile
   (format "mpremote connect %s run main.py"
           (pico/ensure-port))))

(defun pico/reset ()
  "Reset Pico."
  (interactive)
  (compile
   (format "mpremote connect %s reset"
           (pico/ensure-port))))

;;; -----------------------------
;;; C++ (CMake)
;;; -----------------------------

(defun pico/build-cpp ()
  "Build Pico C++ project using CMake."
  (interactive)
  (let* ((root (projectile-project-root))
         (build (expand-file-name "build" root)))
    (unless (file-directory-p build)
      (make-directory build t))
    (compile
     (format "cd %s && cmake -S . -B build && cmake --build build -j"
             root))))


(defun pico/find-uf2 ()
  "Find UF2 file in project build directory."
  (let* ((root (project-root (project-current t)))
         (files (file-expand-wildcards
                 (expand-file-name "build/*.uf2" root))))
    (or (car files)
        (error "No UF2 found in %s" (expand-file-name "build/" root)))))

(defun pico/flash-uf2 ()
  "Flash UF2 to Pico (BOOTSEL mode required)."
  (interactive)
  (let ((mount (pico/mount-path))
        (uf2 (pico/find-uf2)))
    (unless mount
      (error "❌ Pico not in BOOTSEL mode"))
    (unless uf2
      (error "❌ No UF2 found in build/"))
    (compile
     (format "cp %s %s/" uf2 mount))))

(defun pico/build-and-flash ()
  "Build and flash automatically."
  (interactive)
  (pico/build-cpp)
  (run-at-time "1 sec" nil #'pico/flash-uf2))

;;; -----------------------------
;;; Serial Monitor (robust)
;;; -----------------------------

(defun pico/monitor ()
  "Start Pico monitor (smart auto-scroll, no prompts, q to quit)."
  (interactive)
  (pico/monitor-stop)

  (let* ((buf "*pico-monitor*")
         (proc
          (start-process-shell-command
           "pico-monitor"
           buf
           "mpremote connect auto repl")))

    ;; No kill prompt
    (set-process-query-on-exit-flag proc nil)

    ;; SMART SCROLL (only if at bottom)
    (set-process-filter
     proc
     (lambda (process output)
       (with-current-buffer (process-buffer process)
         (let ((moving (= (point) (point-max))))
           (let ((inhibit-read-only t))
             (save-excursion
               (goto-char (point-max))
               (insert output)))
           (when moving
             (goto-char (point-max)))))))

    (pop-to-buffer buf)

    (with-current-buffer buf
      ;; Make it behave like a tool buffer
      (special-mode)

      ;; Press q to quit
      (local-set-key (kbd "q") #'pico/monitor-stop)

      ;; Start at bottom
      (goto-char (point-max)))))

(defun pico/monitor-stop ()
  "Stop Pico monitor and clean window."
  (interactive)
  (let ((buf (get-buffer "*pico-monitor*")))
    (when (get-process "pico-monitor")
      (kill-process "pico-monitor"))
    (when buf
      (let ((win (get-buffer-window buf)))
        (kill-buffer buf)
        (when (window-live-p win)
          (delete-window win)))))
  (setq pico/monitor-running nil)
  (message "🛑 Pico monitor stopped"))

;;; -----------------------------
;;; Smart Runner (ONE KEY)
;;; -----------------------------

(defun pico/run-smart ()
  "Context-aware runner."
  (interactive)
  (cond
   ;; Python
   ((derived-mode-p 'python-mode)
    (pico/upload-python)
    (run-at-time "0.5 sec" nil #'pico/run-python))

   ;; C++
   ((derived-mode-p 'c++-mode)
    (pico/build-cpp))

   (t
    (message "No runner for this mode"))))

;;; -----------------------------
;;; Auto-detect + monitor
;;; -----------------------------

(defvar pico/connected nil)
(defvar pico/monitor-running nil)

(defun pico/check ()
  "Check Pico connection."
  (let ((p (pico/port)))
    (unless (equal p pico/connected)
      (setq pico/connected p)
      (message (if p
                   (format "🔌 Pico connected: %s" p)
                 "❌ Pico disconnected")))))

(defun pico/auto-monitor ()
  "Start monitor automatically."
  (when (and (pico/port)
             (not pico/monitor-running))
    (setq pico/monitor-running t)
    (pico/monitor)))

(run-with-timer 0 5 #'pico/check)

;;; -----------------------------
;;; Modeline
;;; -----------------------------

(defun pico/modeline ()
  (if (pico/port) " 🔌Pico" ""))

(add-to-list 'global-mode-string '(t pico/modeline))

;;; -----------------------------
;;; Comint tuning
;;; -----------------------------

(add-hook 'comint-mode-hook
          (lambda ()
            (setq comint-scroll-to-bottom-on-output t)
            (setq comint-scroll-show-maximum-output t)))

;;; -----------------------------
;;; Keybindings (Doom)
;;; -----------------------------

;;; Global menu
(map! :leader
      (:prefix ("d p" . "pico 🔌")
       :desc "Pico menu" "p" #'pico/hydra/body))

;;; Python-local
(map! :map python-mode-map
      :localleader
      (:prefix ("p" . "pico 🔌")
       :desc "Pico menu" "p" #'pico/hydra/body))

;;; C++-local (🔥 new)
(map! :map c++-mode-map
      :localleader
      (:prefix ("p" . "pico 🔌")
       :desc "Pico menu" "p" #'pico/hydra/body))
