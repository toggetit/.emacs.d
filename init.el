(setq custom-file (make-temp-file "emacs-custom-"))

(custom-set-variables
 '(column-number-indicator-zero-based nil)
 '(column-number-mode t)
 '(current-language-environment "UTF-8")
 '(electric-pair-mode t)
 '(global-display-line-numbers-mode t)
 '(history-delete-duplicates t)
 '(indent-tabs-mode nil)
 '(kill-do-not-save-duplicates t)
 '(kill-read-only-ok t)
 '(make-backup-files nil)
 '(ring-bell-function #'ignore)
 '(scroll-preserve-screen-position t)
 '(standard-indent 2)
 '(tab-always-indent 'complete)
 '(tool-bar-mode nil)
 '(use-short-answers t)
 '(y-or-n-p-use-read-key t t))

(custom-set-faces
 '(default ((t (:family "Droid Sans Mono" :height 140)))))

(put 'downcase-region 'disabled nil)

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

(use-package helm
  :bind
  ([remap execute-extended-command] . helm-M-x)
  ([remap find-file] . helm-find-files)
  (:map helm-map
        ([?\t] . helm-next-line)
        ([backtab] . helm-previous-line))
  :custom
  (helm-split-window-inside-p t))

(use-package helm-projectile
  :custom
  (projectile-completion-system 'helm))

(use-package swiper-helm
  :bind
  ([remap isearch-forward] . swiper-helm))

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
  (load-theme 'doom-dracula t))

(use-package all-the-icons
  :if (display-graphic-p))

;; Flycheck part
(use-package flycheck
  :hook
  (c++-mode . flycheck-mode))

(use-package flycheck-yamllint
  :hook
  (flycheck-mode . flycheck-yamllint-setup))

(use-package company
  :hook
  (c++-mode . company-mode))

(use-package company-terraform
  :hook
  (terraform-mode . company-terraform-init))

(use-package python-mode
  :hook
  (python-mode . flycheck-mode)
  (python-mode . company-mode)
  (python-mode . (lambda () (add-to-list 'write-file-functions 'delete-trailing-whitespace))))

(use-package puppet-mode
  :custom
  (flycheck-puppet-lint-disabled-checks
   '("80chars"
     "140chars"
     "autoloader_layout"
     "documentation"
     "inherits_across_namespaces"
     "selector_inside_resource"
     "variable_scope"))
  :hook
  (puppet-mode . flycheck-mode)
  (puppet-mode . company-mode)
  (puppet-mode . (lambda () (add-to-list 'write-file-functions 'delete-trailing-whitespace))))

(use-package yaml-mode
  :custom
  (flycheck-disabled-checkers '(yaml-ruby))
  :hook
  (yaml-mode . flycheck-mode)
  (yaml-mode . company-mode))

(use-package terraform-mode
  :hook
  (terraform-mode . flycheck-mode)
  (terraform-mode . company-mode)
  (terraform-mode . terraform-format-on-save-mode))

(use-package ansible)
