;;; init.el --- private config file -*- lexical-binding: t -*-

;;; Commentary:

;; https://github.com/toggetit/.emacs.d

;;; Code:

(prefer-coding-system 'utf-8-unix)
(set-language-environment "UTF-8")

;; Setup customize file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
;; Setup local customization file
(defvar local-custom-file (expand-file-name "local.el" user-emacs-directory))
(when (file-exists-p local-custom-file)
  (load local-custom-file))

(setopt
 column-number-indicator-zero-based nil
 column-number-mode t
 electric-pair-mode t
 global-display-line-numbers-mode t
 history-delete-duplicates t
 indent-tabs-mode nil
 inhibit-startup-screen t
 kill-do-not-save-duplicates t
 kill-read-only-ok t
 load-prefer-newer t
 make-backup-files nil
 ring-bell-function #'ignore
 save-place-mode t
 scroll-preserve-screen-position t
 standard-indent 2
 tab-always-indent 'complete
 tool-bar-mode nil
 use-short-answers t
 y-or-n-p-use-read-key t)

(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

;; OSX compatible bindings
(when (memq window-system '(mac ns x))
  (global-set-key [home] 'move-beginning-of-line)
  (global-set-key [end] 'move-end-of-line)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'none))

;; PuTTY fix. Ugly. Bad. But it works. (Good)
(define-key global-map "\M-[1~" 'beginning-of-line)
(define-key global-map [select] 'end-of-line)

;; Sort lines key bind
(global-set-key (kbd "C-c C-s") 'sort-lines)

;; Full screen start
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Delete trailing whitespaces on c++-mode
(add-hook 'prog-mode-hook
    (lambda ()
      (add-to-list 'write-file-functions 'delete-trailing-whitespace)))

;; Flycheck need english compiler messages sometimes
;; https://github.com/flycheck/flycheck/issues/1578
(setenv "LC_MESSAGES" "C")

;; Add repos
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))
(require 'package)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package-ensure)
(setq use-package-always-ensure t)

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

(use-package gitlab-ci-mode)

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
  (:map helm-map
        ("<tab>" . helm-execute-persistent-action)
        ("TAB" . helm-execute-persistent-action))
  :config
  (helm-mode 1)
  :custom
  (helm-split-window-inside-p t))

(use-package helm-icons
  :after
  (all-the-icons)
  :config
  (helm-icons-enable)
  :custom
  (helm-icons-provider 'all-the-icons))

(use-package helm-projectile
  :config
  (helm-projectile-on))

(use-package helm-swoop
  :bind
  ([remap isearch-forward] . helm-swoop-from-isearch))

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
  :config
  (doom-modeline-mode t))

(use-package doom-themes
  :config
  (load-theme 'doom-dracula t)
  (doom-themes-org-config)
  :custom
  (doom-themes-enable-bold t)
  (doom-themes-enable-italic t))

;; Need to M-x all-the-icons-install-fonts
(use-package all-the-icons
  :if (display-graphic-p))

;; Need to M-x nerd-icons-install-fonts
(use-package nerd-icons)

(use-package rainbow-delimiters
  :hook prog-mode)

(use-package markdown-mode
  :mode ("README\\.md\\'" . gfm-mode)
  :custom
  (markdown-command "multimarkdown"))

;; Flycheck part
(use-package flycheck
  :hook prog-mode)

(use-package flycheck-yamllint
  :hook
  (flycheck-mode . flycheck-yamllint-setup))
;; End flycheck part

;;; Company part
;; For company mode in python we need python lsp server package
(use-package company
  :hook prog-mode)

(use-package company-box
  :hook company-mode)

(use-package company-terraform
  :hook
  (terraform-mode . company-terraform-init))
;;; End company part

;;; Eglot
(use-package eglot
  :hook
  (python-mode . eglot-ensure)
  ;; Disable flymake ugly way
  (eglot-managed-mode . (lambda () (flymake-mode -1))))

(use-package jinja2-mode)

(use-package ruby-mode)

(use-package puppet-mode
  :custom
  (flycheck-puppet-lint-disabled-checks
   '("80chars"
     "140chars"
     "autoloader_layout"
     "documentation"
     "inherits_across_namespaces"
     "selector_inside_resource"
     "variable_scope")))

(use-package yaml-mode
  :custom
  (flycheck-disabled-checkers '(yaml-ruby)))

(use-package json-mode)

(use-package hcl-mode)

(use-package terraform-mode
  :hook
  (terraform-mode . terraform-format-on-save-mode))

(use-package dockerfile-mode)

(use-package docker-compose-mode
  :init
  (add-to-list 'auto-mode-alist '("compose[^/]*\\.ya?ml$" . docker-compose-mode)))

(use-package beacon
  :config
  (beacon-mode t))

(use-package undo-tree
  :config
  (global-undo-tree-mode t)
  :custom
  (undo-tree-visualizer-diff t)
  (undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
  (undo-tree-visualizer-timestamps t))

;; (use-package treemacs
;;   :ensure t
;;   :defer t
;;   :custom
;;   (treemacs-width 27)
;;   (treemacs-follow-mode t)
;;   (treemacs-filewatch-mode t)
;;   (treemacs-text-scale -3)
;;   (treemacs-resize-icons 44)
;;   (treemacs-git-commit-diff-mode t)
;;   :bind-keymap
;;   ("C-c t p" . treemacs-project-map)
;;   ("C-c t w" . treemacs-workspace-map))

;; (use-package treemacs-projectile
;;   :after (treemacs projectile)
;;   :ensure t)

;; (use-package treemacs-icons-dired
;;   :hook (dired-mode . treemacs-icons-dired-enable-once)
;;   :ensure t)

;; (use-package treemacs-magit
;;   :after (treemacs magit)
;;   :ensure t)

;; (use-package treemacs-nerd-icons
;;   :after (treemacs nerd-icons)
;;   :ensure t)

(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-initialize)))

;; (treemacs-start-on-boot)

(provide 'init)
;;; init.el ends here
