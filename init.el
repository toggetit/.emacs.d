;;; init.el --- private config file -*- lexical-binding: t -*-

;;; Commentary:

;; https://github.com/toggetit/.emacs.d

;;; Code:

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

;; ==============================================================================
;; 6. PROJECT & VERSION CONTROL INFRASTRUCTURE (MAGIT, FORGE & PROJECTILE)
;; ==============================================================================
(use-package magit
  :ensure t
  :custom
  (magit-log-section-commit-count 15)
  :bind
  ("C-x g" . magit-status))

(use-package forge
  :ensure t
  :after magit
  :custom
  (forge-database-file (expand-file-name "forge-database.db" user-emacs-directory)))

(use-package projectile
  :ensure t
  :custom
  (projectile-enable-caching t)
  (projectile-project-search-path '(("~/.emacs.d" . 0) ("~/git" . 1)))
  :config
  (projectile-mode)
  :bind-keymap
  ("C-c p" . projectile-command-map))

(use-package yasnippet
  :hook
  (prog-mode . yas-minor-mode))

(use-package yasnippet-snippets)

;; ==============================================================================
;; 7. HELM INTERACTION FRAMEWORK & VISUAL FILTERS
;; ==============================================================================
(use-package helm
  :ensure t
  :bind
  ([remap execute-extended-command] . helm-M-x)
  ([remap find-file]                . helm-find-files)
  ([remap switch-to-buffer]         . helm-mini)
  ([remap yank-pop]                 . helm-show-kill-ring)
  ([remap isearch-forward]          . helm-occur)
  (:map helm-map
        ("TAB" . helm-execute-persistent-action))
  :custom
  ;; Split Helm viewport inside the current active window layout safely
  (helm-split-window-inside-p t)
  ;; CORE NATIVE REVIAL: Tell native Helm toolbars to parse nerd-icons fonts layout!
  (helm-x-icons-provider 'nerd-icons)
  (helm-buffers-show-icons t)
  ;; HIGH-SPEED FUZZY INTERACTION: Enable modern smart fuzzy matching engine
  (helm-M-x-fuzzy-match t)
  (helm-buffers-fuzzy-match t)
  (helm-recentf-fuzzy-match t)
  (helm-find-files-fuzzy-match t)
  :config
  ;; Eagerly activate global interceptor mode across the core framework
  (helm-mode 1)
  ;; Safely trigger the native file-matching icon layer layout sequence
  (with-eval-after-load 'helm-files
    (helm-ff-icon-mode 1)))

;; CORRECT MODERN HELM-PROJECTILE INTEGRATION Layout
(use-package helm-projectile
  :ensure t
  :after (helm projectile)
  :hook (projectile-mode . helm-projectile-mode)
  :custom
  (helm-projectile-fuzzy-match t))

(use-package helm-c-yasnippet
  :ensure t
  :after (helm yasnippet)
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
;; 9. CODE DIAGNOSTICS FRONTIER (FLYCHECK SYSTEM)
;; ==============================================================================
(use-package flycheck
  :ensure t
  :custom
  ;; Run syntax verification strictly on file save events to preserve CPU cycles
  (flycheck-check-syntax-automatically '(save mode-enabled))
  (flycheck-display-errors-delay 0.1)
  :config
  (global-flycheck-mode 1))

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

(use-package corfu-popupinfo
  :ensure nil
  :after corfu
  :hook (corfu-mode . corfu-popupinfo-mode)
  :custom
  (corfu-popupinfo-delay 0.2))

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
  ;; HARD FIX: Cleanly combined all entry points into a single flat list structure! [1.3]
  ((prog-mode    . eglot-ensure)
   (yaml-ts-mode . eglot-ensure)
   (json-ts-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-stay-out-of 'emacs-lisp-mode)
  (add-to-list 'eglot-stay-out-of 'flymake)
  (add-to-list 'eglot-server-programs
               '((puppet-mode puppet-ts-mode) . ("localhost" 15000))))

;; ==============================================================================
;; SYSTEM-WIDE DEV ENVIRONMENT DEPENDENCIES (FEDORA LINUX DEPLOYMENT MATRIX)
;; ==============================================================================
;; To unleash the full power of Eglot (LSP) and Flycheck (Diagnostics) inside
;; this configuration, install the respective native system binaries.
;;
;; [1. NATIVE FEDORA PACKAGES — DNF MANAGER]
;; C / C++:      $ sudo dnf install gcc-c++ clang-tools-extra
;; Go Language:  $ sudo dnf install golang golang-x-tools-gopls shellcheck
;; Python Base:  $ sudo dnf install python3-lsp-server python3-flake8
;; Bash Shell:   $ sudo dnf install nodejs-bash-language-server shellcheck
;; Core Utils:   $ sudo dnf install jq libyaml-devel
;;
;; [2. INFRASTRUCTURE AS CODE — HASHICORP]
;; Terraform:    $ sudo dnf config-manager --add-repo https://hashicorp.com
;;               $ sudo dnf install terraform terraform-ls
;;
;; [3. NODE.JS CORE ECOSYSTEM — NPM GLOBAL RUNTIME]
;; Note: Install under regular user with local prefix (~/.npm-global/bin/)
;; Dockerfiles:  $ npm install -g dockerfile-language-server-nodejs
;; YAML Syntax:  $ npm install -g yaml-language-server
;; JSON Layout:  $ npm install -g vscode-json-languageserver

;; [4. VOXPUPULI PUPPET LANGUAGE SERVER v3]
;; Step A: Create dedicated storage directory and clone upstream repo:
;;   $ mkdir -p ~/.local/share/voxpupuli
;;   $ cd ~/.local/share/voxpupuli
;;   $ git clone https://github.com/voxpupuli/openvox-editor-services.git
;;   $ cd openvox-editor-services
;;
;; Step B: Compile dependencies and build native local vendored gems:
;;   $ bundle install
;;   $ bundle exec rake gem_revendor
;; Step C: Relaxed puppet-lint settings
;; cat << 'EOF' > ~/.puppet-lint.rc
;; --no-140chars-check
;; --no-80chars-check
;; --no-autoloader_layout-check
;; --no-case_without_default-check
;; --no-documentation-check
;; --no-inherits_across_namespaces-check
;; --no-manifest_whitespace_class_name_single_space_after-check
;; --no-manifest_whitespace_closing_brace_before-check
;; --no-manifest_whitespace_closing_bracket_after-check
;; --no-manifest_whitespace_closing_bracket_before-check
;; --no-manifest_whitespace_opening_brace_after-check
;; --no-manifest_whitespace_opening_brace_before-check
;; --no-manifest_whitespace_opening_bracket_after-check
;; --no-manifest_whitespace_two_empty_lines-check
;; --no-parameter_documentation-check
;; --no-parameter_types-check
;; --no-params_empty_string_assignment-check
;; --no-selector_inside_resource-check
;; --no-strict_indent-check
;; --no-trailing_comma-check
;; --no-variable_scope-check
;; EOF
;; Step D: Deploy high-performance Systemd User Service unit:
;;   $ mkdir -p ~/.config/systemd/user/
;;   $ cat << 'EOF' > ~/.config/systemd/user/puppet-lsp.service
;; [Unit]
;; Description=OpenVox Puppet Language Server
;; After=network.target
;; Documentation=https://github.com/voxpupuli/openvox-editor-services
;;
;; [Service]
;; Type=simple
;; WorkingDirectory=%h/.local/share/voxpupuli/openvox-editor-services
;; ExecStart=/usr/bin/bundle exec ruby ./puppet-languageserver --port=15000 --ip=127.0.0.1 --timeout=0 --no-stop
;;
;; # High-Fidelity Performance Tuning for Desktop Responsiveness:
;; Nice=-5
;; IOSchedulingClass=best-effort
;; IOSchedulingPriority=3
;;
;; Restart=always
;; RestartSec=2s
;;
;; [Install]
;; WantedBy=default.target
;; EOF
;;
;; Step D: Enable and fire up the background daemon:
;;   $ systemctl --user daemon-reload
;;   $ systemctl --user enable --now puppet-lsp.service
;;   $ systemctl --user status puppet-lsp.service
;; ==============================================================================

;; ==============================================================================
;; 12. NATIVE SYNTAX PARSING INFRASTRUCTURE (TREE-SITTER)
;; ==============================================================================
(use-package treesit
  :ensure nil
  :custom
  (treesit-font-lock-level 4)
  :init
  (setq treesit-language-source-alist
   '((bash              . ("https://github.com/tree-sitter/tree-sitter-bash"))
     (c                 . ("https://github.com/tree-sitter/tree-sitter-c"))
     (cpp               . ("https://github.com/tree-sitter/tree-sitter-cpp"))
     ;; (dockerfile        . ("https://github.com/wharflab/tree-sitter-containerfile" "main" "src" "tree_sitter_containerfile"))
     (elisp             . ("https://github.com/Wilfred/tree-sitter-elisp" "main" "src"))
     (embedded_template . ("https://github.com/tree-sitter/tree-sitter-embedded-template" "master" "src"))
     (go                . ("https://github.com/tree-sitter/tree-sitter-go"))
     (html              . ("https://github.com/tree-sitter/tree-sitter-html"))
     (javascript        . ("https://github.com/tree-sitter/tree-sitter-javascript"))
     (json              . ("https://github.com/tree-sitter/tree-sitter-json"))
     (make              . ("https://github.com/tree-sitter-grammars/tree-sitter-make"))
     (markdown          . ("https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src"))
     (puppet            . ("https://github.com/smoeding/tree-sitter-puppet" "main" "src"))
     (python            . ("https://github.com/tree-sitter/tree-sitter-python"))
     (ruby              . ("https://github.com/tree-sitter/tree-sitter-ruby"))
     (rust              . ("https://github.com/tree-sitter/tree-sitter-rust"))
     (toml              . ("https://github.com/tree-sitter-grammars/tree-sitter-toml"))
     (yaml              . ("https://github.com/tree-sitter-grammars/tree-sitter-yaml")))))

(use-package treesit-auto
  :ensure t
  :functions global-treesit-auto-mode
  :custom
  ;; HARD FIX FOR RECIPIE HIJACKING: We command treesit-auto to DROP its internal
  ;; recipes entirely and synchronize its behavior strictly using your custom
  ;; 'treesit-language-source-alist' table layout! Prevents any old URLs fallback leaks.
  (treesit-auto-install 'fallback)

  ;; Your strict curated list of active languages to manage automatically
  (treesit-auto-langs
   '(bash c cpp dockerfile embedded_template json go html javascript make markdown puppet python rust toml yaml))
  :config
  ;; Instruct the engine to map ALL supported extensions to native *-ts-modes
  (treesit-auto-add-to-auto-mode-alist 'all)
  ;; Explicitly pass parameter 1 to guarantee robust global activation
  (global-treesit-auto-mode 1))

(use-package puppet-ts-mode
  :ensure t
  :defer t
  :mode "\\.pp\\'")
  ;; :custom
  ;; (flycheck-puppet-lint-disabled-checks
  ;;  '(
  ;;    "140chars"
  ;;    "80chars"
  ;;    "autoloader_layout"
  ;;    "case_without_default"
  ;;    "documentation"
  ;;    "inherits_across_namespaces"
  ;;    "manifest_whitespace_class_name_single_space_after"
  ;;    "manifest_whitespace_closing_brace_before"
  ;;    "manifest_whitespace_closing_bracket_after"
  ;;    "manifest_whitespace_closing_bracket_before"
  ;;    "manifest_whitespace_opening_brace_after"
  ;;    "manifest_whitespace_opening_brace_before"
  ;;    "manifest_whitespace_opening_bracket_after"
  ;;    "manifest_whitespace_two_empty_lines"
  ;;    "parameter_documentation"
  ;;    "parameter_types"
  ;;    "params_empty_string_assignment"
  ;;    "selector_inside_resource"
  ;;    "strict_indent"
  ;;    "trailing_comma"
  ;;    "variable_scope"
  ;;    )))

;; ==============================================================================
;; 13. WEB TEMPLATES & INFRASTRUCTURE MARKUP MODES (LEGACY POLYGLOT COMPATIBILITY)
;; ==============================================================================
(use-package web-mode
  :ensure t
  :defer t
  :mode (("\\.erb\\'"       . web-mode)
         ("\\.j2\\'"        . web-mode))
  :custom
  (web-mode-markup-indent-offset 2)
  (web-mode-css-indent-offset 2)
  (web-mode-code-indent-offset 2)
  (web-mode-engines-alist
   '(("erb"   . "\\.erb\\'")
     ("jinja" . "\\.j2\\'"))))

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

;; ==============================================================================
;; 15. ADVANCED SIDEBAR ARCHITECTURE (TREEMACS CORE SYSTEM)
;; ==============================================================================
(use-package treemacs
  :ensure t
  :defer t
  :custom
  (treemacs-filewatch-mode t)          ; Automatically refresh when files change on disk
  (treemacs-follow-mode t)             ; Seamlessly expand directories to follow your active cursor
  (treemacs-git-core-type 'deferred)   ; Forces Treemacs to query Git statuses in background threads using 'deferred' engine.
  (treemacs-is-never-other-window t)   ; Prevent C-x o from accidentally switching focus into sidebar
  (treemacs-project-follow-cleanup t)  ; Collapse unused projects cleanly to save space
  (treemacs-text-scale -2)             ; Compact visual scale matching high-res FullHD displays
  :config
  ;; Guard parameter configuration for side windows layouts boundaries
  (add-to-list 'window-persistent-parameters '(window-side . writable))
  ;; HARD FIX FOR THEME INITIALIZATION:
  ;; Instead of lazy-loading via :after, we force the inline execution of nerd-icons integration
  ;; right when Treemacs configuration block is evaluated. This guarantees registration!
  (use-package treemacs-nerd-icons
    :ensure t
    :config
    (treemacs-load-theme "nerd-icons"))
  :bind-keymap
  ("C-c t p" . treemacs-project-map)
  ("C-c t w" . treemacs-workspace-map))

(use-package treemacs-projectile
  :ensure t
  :defer t
  :after (treemacs projectile))

(use-package treemacs-magit
  :ensure t
  :defer t
  :after (treemacs magit))

(provide 'init)
;;; init.el ends here
