(custom-set-variables
 '(column-number-indicator-zero-based nil)
 '(column-number-mode t)
 '(current-language-environment "UTF-8")
 '(custom-enabled-themes '(wombat))
 '(electric-pair-mode t)
 '(global-display-line-numbers-mode t)
 '(history-delete-duplicates t)
 '(indent-tabs-mode nil)
 '(kill-do-not-save-duplicates t)
 '(make-backup-files nil)
 '(ring-bell-function #'ignore))
 '(scroll-preserve-screen-position t)
 '(standard-indent 2)
 '(tab-always-indent 'complete)
 '(tool-bar-mode nil)
 '(use-short-answers t)
(custom-set-faces
 '(default ((t (:family "Droid Sans Mono" :foundry "1ASC" :slant normal :weight normal :height 140 :width normal)))))

;; PuTTY fix. Ugly. Bad. But it works. (Good)
(define-key global-map "\M-[1~" 'beginning-of-line)
(define-key global-map [select] 'end-of-line)

;; Full screen start
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Delete trailing whitespaces on c++-mode
(add-hook 'c++-mode-hook
    (lambda ()
      (add-to-list 'write-file-functions 'delete-trailing-whitespace)))

;; Flycheck need english compiler messages sometimes
;; https://github.com/flycheck/flycheck/issues/1578
(setenv "LC_MESSAGES" "C")

;; Add repos
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")
                         ("melpa" . "https://melpa.org/packages/")))
(require 'package)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(use-package projectile
  :ensure t
  :config
  (projectile-mode)
  (setq projectile-enable-caching t)
  (setq projectile-indexing-method 'native)
  (setq projectile-auto-discover nil)
  (setq projectile-project-search-path '(("~/.emacs.d" . 0), ("~/git" . 0)))
  ;; Old search method
  ;; (setq projectile-completion-system 'ido)
  :bind-keymap
  ("C-c p" . projectile-command-map))

(use-package helm-projectile
  :ensure t
  :config
  (setq projectile-completion-system 'helm))

(use-package ergoemacs-status
  :ensure t
  :config
  (ergoemacs-status-mode))

(use-package magit
  :ensure t)

(use-package flycheck
  :ensure t
  :hook
  (c++-mode . flycheck-mode))

(use-package flycheck-yamllint
  :ensure t
  :hook
  (flycheck-mode . flycheck-yamllint-setup))

(use-package company
  :ensure t
  :hook
  (c++-mode . company-mode))

(use-package company-terraform
  :ensure t
  :hook
  (terraform-mode . company-terraform-init))

(use-package python-mode
  :ensure t
  :hook
  (python-mode . flycheck-mode)
  (python-mode . company-mode)
  (python-mode . (lambda () (add-to-list 'write-file-functions 'delete-trailing-whitespace)))
  :config
  (setq flycheck-puppet-lint-disabled-checks
	'("80chars"
	  "autoloader_layout"
	  "documentation"
	  "inherits_across_namespaces"
	  "selector_inside_resource"
	  "variable_scope")))

(use-package puppet-mode
  :ensure t
  :hook
  (puppet-mode . flycheck-mode)
  (puppet-mode . company-mode)
  (puppet-mode . (lambda () (add-to-list 'write-file-functions 'delete-trailing-whitespace))))

(use-package yaml-mode
  :ensure t
  :hook
  (yaml-mode . flycheck-mode)
  (yaml-mode . company-mode)
  :config
  (setq flycheck-disabled-checkers '(yaml-ruby)))

(use-package terraform-mode
  :ensure t
  :hook
  (terraform-mode . flycheck-mode)
  (terraform-mode . company-mode)
  (terraform-mode . terraform-format-on-save-mode))

(use-package ansible
  :ensure t)

(put 'downcase-region 'disabled nil)
