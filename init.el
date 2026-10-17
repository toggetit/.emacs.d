;;; init.el --- private config file -*- lexical-binding: t -*-

;;; Commentary:

;; https://github.com/toggetit/.emacs.d

;;; Code:
;;; init.el --- private config file -*- lexical-binding: t -*-

;; ==============================================================================
;; 1. CORE SYSTEM PERFORMANCES & ENVIRONMENT TUNING
;; ==============================================================================
;; Force absolute UTF-8 environment regardless of how systemd daemon starts
(prefer-coding-system 'utf-8-unix)
(set-language-environment "UTF-8")

;; Garbage Collector Optimization: Prevents stutters in active modern LSP environments.
;; We set a healthy 32MB runtime ceiling instead of the ancient 800KB default.
(setq gc-cons-threshold (* 32 1024 1024)
      gc-cons-percentage 0.1)

;; Maximize process output reading chunks (Critical for Eglot/LSP server responses)
(setq read-process-output-max (* 1024 1024)) ; 1MB stream block

;; Setup customize files
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(defvar local-custom-file (expand-file-name "local.el" user-emacs-directory))
(when (file-exists-p local-custom-file)
  (load local-custom-file))

;; ==============================================================================
;; 2. EMACS INTERNAL ENVIRONMENT OPTIMIZATIONS
;; ==============================================================================
(setopt
 column-number-indicator-zero-based nil
 column-number-mode t
 electric-pair-mode t
 global-display-line-numbers-mode t
 history-delete-duplicates t
 indent-tabs-mode nil
 inhibit-startup-screen t
 inhibit-startup-message t
 inhibit-startup-echo-area-message (eval user-login-name)
 kill-do-not-save-duplicates t
 kill-read-only-ok t
 load-prefer-newer t
 make-backup-files nil
 ring-bell-function #'ignore
 save-place-mode t
 scroll-preserve-screen-position t
 standard-indent 2
 tab-always-indent 'complete
 use-short-answers t
 y-or-n-p-use-read-key t)

(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

;; Sort lines key bind
(global-set-key (kbd "C-c C-s") 'sort-lines)

;; Flycheck needs English compiler messages for precise pattern parsing
(setenv "LC_MESSAGES" "C")

;; Automatically clean up trailing whitespaces before saving,
;; buffer-locally and strictly inside programming modes.
(add-hook 'prog-mode-hook
          (lambda ()
            (add-hook 'before-save-hook #'delete-trailing-whitespace nil t)))

;; ==============================================================================
;; 3. ADVANCED GRAPHICAL WINDOW ACCELERATION & CAPABILITY HOOKS
;; ==============================================================================
;; This function applies typography and geometry dynamically ONLY when a GUI frame is spawned.
;; It safely preserves core CLI-mode ergonomics if Emacs is called inside a Kitty/Alacritty window.
(defun my/configure-graphical-frame (frame)
  "Applies high-fidelity visual configurations for graphical interfaces."
  (with-selected-frame frame
    (when (display-graphic-p frame)
      ;; Disable scrollbars inside the UI frame viewport
      (scroll-bar-mode -1)
      (tool-bar-mode -1)
      (menu-bar-mode -1)

      ;; Maximize frame geometry on your Samsung screens out of the box
      (set-frame-parameter frame 'fullscreen 'maximized)

      ;; Core Interface Typography (Roboto Mono for logic, Fira Sans for documentation)
      (set-face-attribute 'default nil :font "Roboto Mono-12" :weight 'normal :width 'normal)
      (set-face-attribute 'fixed-pitch nil :font "Roboto Mono-12")
      (set-face-attribute 'variable-pitch nil :font "Fira Sans-12")

      ;; Desktop OS modifiers fallback mapping
      (when (memq window-system '(mac ns x))
        (global-set-key [home] 'move-beginning-of-line)
        (global-set-key [end] 'move-end-of-line)
        (setq mac-command-modifier 'meta
              mac-option-modifier 'none)))))

;; Bind the initialization hook for daemon-client runtimes and cold GUI boots
(if (daemonp)
    (add-hook 'after-make-frame-functions #'my/configure-graphical-frame)
  (my/configure-graphical-frame (selected-frame)))

;; ==============================================================================
;; 4. PACKAGE ARCHIVE SYSTEM INITIALIZATION
;; ==============================================================================
;; Modern Emacs (28+) includes GNU and NonGNU ELPA by default.
;; We only append MELPA — the vital community package matrix tracker.
(require 'package)

(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(package-initialize)

(require 'use-package-ensure)
(setq use-package-always-ensure t)

;; ==============================================================================
;; 14. SYSTEM ENVIRONMENT PATH SYNCHRONIZATION
;; ==============================================================================
(use-package exec-path-from-shell
  :ensure t
  ;; If Emacs runs as a headless systemd daemon or under macOS,
  ;; we must explicitly synchronize the internal exec-path matrix with the user shell environment.
  :init
  (when (or (daemonp) (memq window-system '(mac ns)))
    (exec-path-from-shell-initialize)))

(use-package vterm)

;; Persist history over Emacs restarts.
(use-package savehist
  :init
  (savehist-mode))

(use-package magit
  :custom
  (magit-completing-read-function 'helm--completing-read-default)
  (magit-log-section-commit-count 15))

(use-package forge
  :after magit)

(use-package projectile
  :custom
  (projectile-enable-caching t)
  (projectile-project-search-path
   '(("~/.emacs.d" . 0) ("~/git" . 1)))
  ;; Old search method
  ;; (projectile-completion-system 'ido)
  :config
  (projectile-mode)
  :bind-keymap
  ("C-c p" . projectile-command-map))

(use-package yasnippet
  :hook
  (prog-mode . yas-minor-mode))

(use-package yasnippet-snippets)

(use-package helm
  :bind
  ([remap execute-extended-command] . helm-M-x)
  ([remap find-file] . helm-find-files)
  ([remap isearch-backward] . previous-complete-history-element)
  ([remap switch-to-buffer] . helm-mini)
  ([remap yank-pop] . helm-show-kill-ring)
  ([remap isearch-forward] . helm-occur)
  (:map helm-map
        ("TAB" . helm-execute-persistent-action))
  :config
  (helm-mode 1)
  :custom
  (helm-split-window-inside-p t))

(use-package helm-projectile
  :config
  (helm-projectile-on))

(use-package helm-gtags
  :custom
  (helm-gtags-ignore-case t)
  (helm-gtags-auto-update t)
  (helm-gtags-use-input-at-cursor t)
  (helm-gtags-pulse-at-cursor t)
  ;; (helm-gtags-prefix-key "\C-cg")
  (helm-gtags-suggested-key-mapping t)
  :hook
  (c++-mode))

(use-package helm-c-yasnippet
  :custom
  (helm-yas-space-match-any-greedy t)
  :bind
  ("C-c y" . helm-yas-complete))

(use-package helpful
  :bind
  ([remap describe-function] . helpful-callable)
  ([remap describe-variable] . helpful-variable)
  ([remap describe-key] . helpful-key))

(use-package which-key
  :config
  (which-key-mode))

(use-package doom-modeline
  :custom
  (doom-modeline-font-family "nerd-icons")
  (doom-modeline-icon t)
  :config
  (doom-modeline-mode t))

(use-package doom-themes
  :config
  (load-theme 'doom-dracula t)
  (doom-themes-org-config)
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t))

;; Need to M-x nerd-icons-install-fonts
(use-package nerd-icons)

(use-package rainbow-delimiters
  :hook prog-mode)

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  :custom
  (markdown-command "multimarkdown"))

;; ==============================================================================
;; 9. CODE DIAGNOSTICS FRONTIER (FLYCHECK)
;; ==============================================================================
(use-package flycheck
  :ensure t
  :hook (prog-mode . global-flycheck-mode))

(use-package flycheck-yamllint
  :ensure t
  :after flycheck
  :hook (flycheck-mode . flycheck-yamllint-setup))

;; MODERN LSP DIAGNOSTICS BRIDGE:
;; Forces Eglot to seamlessly stream its background LSP compilation errors
;; straight into our beautiful Flycheck frontend window layout.
(use-package flycheck-eglot
  :ensure t
  :after (flycheck eglot)
  :hook (global-flycheck-mode . global-flycheck-eglot-mode))

;; ==============================================================================
;; 10. MODERN TEXT COMPLETION ENGINE (CORFU SYSTEM)
;; ==============================================================================
(use-package corfu
  :ensure t
  ;; Corfu is designed to hook into standard Emacs completion-at-point mechanics
  :hook
  (prog-mode . corfu-mode)
  :bind
  ;; Snappy navigation inside the active popup menu
  (:map corfu-map
        ("TAB"     . corfu-next)
        ([tab]     . corfu-next)
        ("S-TAB"   . corfu-previous)
        ([backtab] . corfu-previous)
        ("RET"     . corfu-insert))
  :custom
  (corfu-cycle t)                ; Allow cycling through the candidates list
  (corfu-auto t)                 ; Enable snappy automatic completion popups
  (corfu-auto-prefix 2)          ; Trigger completion after typing 2 characters
  (corfu-auto-delay 0.1)         ; Snappy response delay (100ms)
  (corfu-quit-at-boundary 'separator) ; Better handling for LSP boundaries
  (corfu-echo-documentation nil) ; Disable document echo in minibuffer to save CPU
  :config
  ;; Global micro-mode setup for internal frame buffers
  (global-corfu-mode 1))

;; HIGH-SPEED VECTOR ICONS FOR CORFU POPUPS
(use-package nerd-icons-corfu
  :ensure t
  :after corfu
  :config
  ;; Dynamically inject the clean vector font formatter into Corfu layout
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

;; ==============================================================================
;; 10a. COMPLETION AT POINT EXTENSIONS (CAPE SYSTEM)
;; ==============================================================================
(use-package cape
  :ensure t
  ;; Lazy load Cape setup hooks
  :init
  ;; We append Cape backends to the END of the list (using parameter t).
  ;; This guarantees that Eglot (LSP) always takes absolute priority in code,
  ;; while Cape acts as a silent, non-intrusive fallback for text and paths!
  (add-to-list 'completion-at-point-functions #'cape-dabbrev t)
  (add-to-list 'completion-at-point-functions #'cape-file t))

;; ==============================================================================
;; 11. NATIVE LANGUAGE SERVER PROTOCOL (EGLOT LSP SYSTEM)
;; ==============================================================================
(use-package eglot
  ;; Eglot is built-in since Emacs 29.1, :ensure nil prevents external downloading
  :ensure nil
  :defer t
  :custom
  (eglot-events-buffer-size 0)
  :hook
  ((prog-mode . eglot-ensure)
   (yaml-ts-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-stay-out-of 'emacs-lisp-mode)
  (add-to-list 'eglot-stay-out-of 'flymake)
  ;; HARD FIX FOR OPENVOX SYSTEM:
  ;; Register the modern voxpupuli openvox-languageserver binary inside Eglot matrix.
  ;; Maps both legacy puppet-mode and native treesitter puppet-ts-mode directly to it.
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 '(puppet-ts-mode . ("openvox-languageserver" "--stdio")))))

;; ==============================================================================
;; SYSTEM-WIDE DEV ENVIRONMENT DEPENDENCIES (FEDORA LINUX DNF INFRASTRUCTURE)
;; ==============================================================================
;; To unleash the full power of Eglot (LSP) and Flycheck (Diagnostics) inside
;; this configuration, install the respective native system binaries via DNF.
;;
;; [CORE LANGUAGES & COMPILERS]
;; C / C++:      $ sudo dnf install gcc-c++ clang-tools-extra
;; Go Language:  $ sudo dnf install golang golang-x-tools-gopls golangci-lint
;; Python:       $ sudo dnf install python3-lsp-server python3-flake8
;; Bash Shell:   $ sudo dnf install nodejs-bash-language-server shellcheck
;; Ruby:         $ sudo dnf install ruby-devel (Note: solargraph requires 'gem install solargraph')
;;
;; [INFRASTRUCTURE AS CODE & CONFIGURATIONS]
;; Terraform:    $ sudo dnf config-manager --add-repo https://hashicorp.com
;;               $ sudo dnf install terraform terraform-ls
;; Dockerfiles:  $ sudo dnf install nodejs && sudo npm install -g dockerfile-language-server-nodejs
;; YAML Syntax:  $ sudo dnf install yamllint && sudo npm install -g yaml-language-server
;; JSON Layout:  $ sudo dnf install nodejs && sudo npm install -g vscode-json-languageserver
;; Markdown:     $ sudo dnf install python3-markdown python3-mdformat
;; ==============================================================================

;; ==============================================================================
;; 12. NATIVE SYNTAX PARSING INFRASTRUCTURE (TREE-SITTER)
;; ==============================================================================
(use-package treesit-auto
  :ensure t
  :functions global-treesit-auto-mode
  :custom
  ;; MAX COMPATIBILITY: Force Emacs to prompt before compiling new language grammars
  (treesit-auto-install 'prompt)

  ;; HIGH-FIDELITY TYPOGRAPHY: Set maximum syntax highlighting depth (Level 4).
  ;; This unlocks gorgeous, rich color coding inside your Doom-Dracula theme!
  (treesit-font-lock-level 4)

  ;; List of active languages we want to automatically manage via Tree-sitter
  (treesit-auto-langs
   '(awk bash c cpp cmake dockerfile jinja2 json go go-mod html make markdown puppet python r ruby rust toml yaml))
  :config
  ;; Instruct the engine to map ALL supported extensions to native *-ts-modes
  (treesit-auto-add-to-auto-mode-alist 'all)
  ;; Explicitly pass parameter 1 to guarantee robust global activation
  (global-treesit-auto-mode 1))

(use-package ruby-mode)

;; ==============================================================================
;; 13. WEB TEMPLATES & INFRASTRUCTURE MARKUP MODES
;; ==============================================================================
(use-package web-mode
  :ensure t
  :defer t
  ;; Lazily maps HTML, ERB, and Jinja2/Ansible templates to a unified engine
  :mode (("\\.erb\\'"       . web-mode)
         ("\\.html\\'"      . web-mode)
         ("\\.j2\\'"        . web-mode)
         ("\\.html\\.j2\\'" . web-mode))
  :custom
  ;; Buffer-local indentation geometry for web tokens (Clean scalar values)
  (web-mode-markup-indent-offset 2)
  (web-mode-css-indent-offset 2)
  (web-mode-code-indent-offset 2)
  ;; Force web-mode to natively activate its lightning-fast Jinja2
  ;; template parsing engine whenever a .j2 file layout is detected.
  ;; Note: NO leading quote sign inside the declarative :custom block!
  (web-mode-engines-alist '(("jinja" . "\\.j2\\'"))))

(use-package puppet-ts-mode
  :ensure t
  :defer t
  :mode "\\.pp\\'"
  :custom
  (flycheck-puppet-lint-disabled-checks
   '("80chars"
     "140chars"
     "autoloader_layout"
     "documentation"
     "inherits_across_namespaces"
     "selector_inside_resource"
     "variable_scope")))

;; ==============================================================================
;; 14. DATA SERIALIZATION MODES (YAML & JSON ECOSYSTEM)
;; ==============================================================================
(use-package yaml-pro
  :ensure t
  :defer t
  ;; Strictly hooks into the native high-speed Tree-sitter viewport buffers.
  ;; No legacy yaml-mode dependencies or regex-parsers are loaded in memory!
  :hook ((yaml-ts-mode . yaml-pro-ts-mode)
         (yaml-pro-ts-mode . eldoc-mode)))

;; CORRECT MODERN JSON CONFIGURATION (Bypassing legacy json-mode)
(use-package json-ts-mode
  :ensure nil
  :defer t
  :mode "\\.json\\'"
  ;; HARD FIX: Corrected syntax from underscore to hyphen to match the true hook name!
  :hook (json-ts-mode . eglot-ensure))

;; ==============================================================================
;; 15. INFRASTRUCTURE AS CODE (TERRAFORM & HCL MANAGEMENT)
;; ==============================================================================
(use-package terraform-mode
  :ensure t
  :defer t
  ;; Handles both standard terraform manifests and general HashiCorp config files safely
  :mode (("\\.tf\\'"  . terraform-mode)
         ("\\.hcl\\'" . terraform-mode))
  :hook
  (terraform-mode . terraform-format-on-save-mode)
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
                 '(terraform-mode . ("terraform-ls" "serve")))))

;; ==============================================================================
;; 14. CONTAINERIZATION ENVIRONMENT (DOCKER INFRASRUCTURE)
;; ==============================================================================
(use-package dockerfile-ts-mode
  :ensure nil ; Built-in core mode, do not download anything
  :defer t
  :mode "Dockerfile\\'")

;; ==============================================================================
;; 17. VISUAL ERGONOMICS & DEEP HISTORIES
;; ==============================================================================
(use-package beacon
  :ensure t
  :defer t
  ;; Lazily hooks the visual cursor pulse whenever switching active buffers
  :hook (window-configuration-change . beacon-mode))

(use-package undo-tree
  :ensure t
  :defer t
  ;; Instantly activates the global visual history matrix upon text modification
  :init
  (global-undo-tree-mode 1)
  :custom
  (undo-tree-visualizer-diff t)
  (undo-tree-visualizer-timestamps t)
  ;; Safe isolation directory layout for absolute state persistence
  (undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo"))))

(use-package treemacs
  :ensure t
  :defer t
  :custom
  ;; (treemacs-width 27)
  (treemacs-filewatch-mode t)
  (treemacs-follow-mode t)
  (treemacs-fringe-indicator-mode 'always)
  (treemacs-git-commit-diff-mode t)
  (treemacs-is-never-other-window t)
  (treemacs-project-follow-cleanup t)
  (treemacs-text-scale -2)
  ;; (treemacs-resize-icons 44)
  :config
  (add-to-list 'window-persistent-parameters
               '(window-side . writable))
  :bind-keymap
  ("C-c t p" . treemacs-project-map)
  ("C-c t w" . treemacs-workspace-map))

(use-package treemacs-projectile
  :after (treemacs projectile)
  :ensure t)

;; (use-package treemacs-icons-dired
;;   :hook (dired-mode . treemacs-icons-dired-enable-once)
;;   :ensure t)

(use-package treemacs-magit
 :after (treemacs magit)
 :ensure t)

(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :ensure t)

;; (treemacs-start-on-boot)
(use-package flycheck-golangci-lint
  :ensure t
  :hook (go-mode . flycheck-golangci-lint-setup))

(provide 'init)
;;; init.el ends here
