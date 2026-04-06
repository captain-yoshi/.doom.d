;;; pico/keybinds.el --- Pico Hydra -*- lexical-binding: t; -*-

(after! hydra
  (defhydra pico/hydra (:color teal :hint nil)
    "
🔌 Pico Dev (Python + C++)

  Python                 C++                  Device
-----------------------------------------------------------
  a: flash MicroPython   b: build             m: monitor
  u: upload .py          B: build+flash       s: stop monitor
  r: run .py             f: flash UF2         R: reset

  d: detect Pico         q: quit
"
    ;; -----------------------------
    ;; Python
    ;; -----------------------------
    ("a" pico/flash-micropython)
    ("u" pico/upload-python)
    ("r" pico/run-python)

    ;; -----------------------------
    ;; C++
    ;; -----------------------------
    ("b" pico/build-cpp)
    ("B" pico/build-and-flash)
    ("f" pico/flash-uf2)

    ;; -----------------------------
    ;; Device / Serial
    ;; -----------------------------
    ("m" pico/monitor)
    ("s" pico/monitor-stop)
    ("R" pico/reset)

    ;; -----------------------------
    ;; Info
    ;; -----------------------------
    ("d"
     (lambda ()
       (interactive)
       (message "Pico port: %s | Mount: %s"
                (or (pico/port) "Not found")
                (or (pico/mount-path) "Not mounted"))))

    ;; -----------------------------
    ;; Exit
    ;; -----------------------------
    ("q" nil "quit")))
