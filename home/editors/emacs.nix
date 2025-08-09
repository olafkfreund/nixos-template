{ config, lib, pkgs, ... }:

{
  # Emacs configuration with modern packages and sensible defaults
  # This configuration provides a comprehensive Emacs setup with:
  # - LSP support for multiple languages
  # - Modern completion framework (Vertico + Consult)
  # - Git integration (Magit)
  # - Project management (Projectile)
  # - Org-mode enhancements
  # - Development tools and utilities

  programs.emacs = {
    enable = true;
    package = pkgs.emacs29-pgtk; # Emacs 29 with pure GTK (better Wayland support)

    extraPackages = epkgs: with epkgs; [
      # Core packages for modern Emacs experience
      use-package # Package configuration macro
      diminish # Hide minor modes from modeline
      bind-key # Key binding helpers

      # Completion and narrowing framework
      vertico # Vertical completion UI
      orderless # Completion style for matching
      marginalia # Rich annotations for minibuffer
      consult # Consulting commands (enhanced search/navigation)
      embark # Contextual actions
      embark-consult # Consult integration for Embark

      # Search and navigation
      avy # Jump to visible text
      swiper # Interactive search
      ivy # Alternative completion framework (if preferred)
      counsel # Ivy-enhanced versions of common commands

      # File and project management
      projectile # Project interaction library
      dired-single # Enhanced directory editor
      dired-ranger # File operations for dired
      all-the-icons # Icon fonts for various packages
      all-the-icons-dired # Icons in dired
      neotree # File tree explorer

      # Git integration
      magit # Git porcelain
      git-gutter # Show git diff in gutter
      git-timemachine # Walk through git revisions
      forge # GitHub/GitLab integration

      # LSP and development
      lsp-mode # Language Server Protocol client
      lsp-ui # UI improvements for LSP
      lsp-treemacs # Treemacs integration for LSP
      company # Text completion framework
      company-lsp # LSP completion backend
      flycheck # Syntax checking
      yasnippet # Template system
      yasnippet-snippets # Snippet collections

      # Language-specific packages
      nix-mode # Nix language support
      rust-mode # Rust language support
      cargo # Cargo integration for Rust
      go-mode # Go language support
      python-mode # Python language support
      js2-mode # JavaScript support
      typescript-mode # TypeScript support
      web-mode # Web template editing
      yaml-mode # YAML support
      json-mode # JSON support
      markdown-mode # Markdown support
      dockerfile-mode # Dockerfile support

      # Org-mode enhancements
      org-bullets # Pretty bullets for org-mode
      org-roam # Note-taking system
      org-journal # Journaling with org-mode
      org-present # Presentation mode

      # Theme and appearance
      doom-themes # Theme collection
      doom-modeline # Modern modeline
      rainbow-delimiters # Colorful parentheses
      highlight-indent-guides # Indent visualization

      # Productivity and utilities
      which-key # Key binding help
      ace-window # Window switching
      winner # Window configuration undo/redo
      undo-tree # Visual undo system
      expand-region # Expand selection semantically
      multiple-cursors # Multiple cursor editing

      # Terminal and shell
      vterm # Full-featured terminal emulator
      shell-pop # Pop-up shell

      # Writing and editing
      writegood-mode # Writing analysis
      flyspell # Spell checking
      abbrev # Abbreviation expansion

      # Performance and startup
      gcmh # Garbage collection magic hack

      # Additional utilities
      helpful # Better help system
      dashboard # Startup dashboard
      recent-files # Recent files management
    ];

    extraConfig = ''
      ;; Emacs Configuration
      ;; This configuration provides a modern Emacs experience with sensible defaults

      ;; Performance optimizations
      (setq gc-cons-threshold 100000000)
      (setq read-process-output-max (* 1024 1024))

      ;; Basic settings
      (setq inhibit-startup-message t)
      (setq initial-scratch-message "")
      (setq ring-bell-function 'ignore)
      (setq make-backup-files nil)
      (setq auto-save-default nil)
      (setq create-lockfiles nil)

      ;; UI improvements
      (menu-bar-mode -1)
      (tool-bar-mode -1)
      (scroll-bar-mode -1)
      (global-display-line-numbers-mode 1)
      (column-number-mode 1)
      (show-paren-mode 1)
      (global-hl-line-mode 1)

      ;; Font configuration
      (set-face-attribute 'default nil :font "JetBrains Mono-12")

      ;; Better defaults
      (setq-default indent-tabs-mode nil)
      (setq-default tab-width 2)
      (setq sentence-end-double-space nil)
      (setq require-final-newline t)
      (global-auto-revert-mode t)

      ;; Use-package configuration
      (require 'use-package)
      (setq use-package-always-ensure t)
      (setq use-package-verbose t)

      ;; Theme
      (use-package doom-themes
        :config
        (setq doom-themes-enable-bold t
              doom-themes-enable-italic t)
        (load-theme 'doom-one t)
        (doom-themes-visual-bell-config)
        (doom-themes-neotree-config)
        (doom-themes-org-config))

      ;; Modeline
      (use-package doom-modeline
        :init (doom-modeline-mode 1)
        :config
        (setq doom-modeline-height 25)
        (setq doom-modeline-buffer-file-name-style 'truncate-upto-project))

      ;; Icons (required for doom-modeline)
      (use-package all-the-icons
        :if (display-graphic-p))

      ;; Completion framework
      (use-package vertico
        :init
        (vertico-mode)
        :config
        (setq vertico-cycle t))

      (use-package orderless
        :init
        (setq completion-styles '(orderless basic)
              completion-category-defaults nil
              completion-category-overrides '((file (styles partial-completion)))))

      (use-package marginalia
        :bind (:map minibuffer-local-map
               ("M-A" . marginalia-cycle))
        :init
        (marginalia-mode))

      (use-package consult
        :bind (("C-s" . consult-line)
               ("C-M-s" . consult-line-multi)
               ("C-x b" . consult-buffer)
               ("C-x 4 b" . consult-buffer-other-window)
               ("C-x r b" . consult-bookmark)
               ("M-g g" . consult-goto-line)
               ("M-g M-g" . consult-goto-line)
               ("M-g i" . consult-imenu)
               ("M-g I" . consult-imenu-multi)
               ("C-x p b" . consult-project-buffer))
        :init
        (setq register-preview-delay 0.5
              register-preview-function #'consult-register-format)
        (advice-add #'register-preview :override #'consult-register-window))

      ;; Key binding help
      (use-package which-key
        :diminish which-key-mode
        :config
        (which-key-mode)
        (setq which-key-idle-delay 0.3))

      ;; Project management
      (use-package projectile
        :diminish projectile-mode
        :config (projectile-mode)
        :bind-keymap
        ("C-c p" . projectile-command-map)
        :init
        (when (file-directory-p "~/Projects")
          (setq projectile-project-search-path '("~/Projects")))
        (setq projectile-switch-project-action #'projectile-dired))

      ;; Git integration
      (use-package magit
        :bind ("C-x g" . magit-status))

      (use-package git-gutter
        :config
        (global-git-gutter-mode +1))

      ;; LSP Mode
      (use-package lsp-mode
        :init
        (setq lsp-keymap-prefix "C-c l")
        :hook ((nix-mode . lsp)
               (rust-mode . lsp)
               (go-mode . lsp)
               (python-mode . lsp)
               (js2-mode . lsp)
               (typescript-mode . lsp)
               (lsp-mode . lsp-enable-which-key-integration))
        :commands lsp
        :config
        (setq lsp-auto-guess-root t)
        (setq lsp-prefer-flymake nil)
        (setq lsp-enable-snippet t))

      (use-package lsp-ui
        :commands lsp-ui-mode
        :config
        (setq lsp-ui-doc-enable t)
        (setq lsp-ui-doc-position 'bottom)
        (setq lsp-ui-sideline-enable t))

      ;; Company mode for completion
      (use-package company
        :diminish company-mode
        :config
        (global-company-mode 1)
        (setq company-idle-delay 0.2)
        (setq company-minimum-prefix-length 1)
        (setq company-selection-wrap-around t))

      ;; Yasnippet
      (use-package yasnippet
        :config
        (yas-global-mode 1))

      (use-package yasnippet-snippets)

      ;; Flycheck
      (use-package flycheck
        :config
        (global-flycheck-mode))

      ;; Language modes
      (use-package nix-mode
        :mode "\\.nix\\'")

      (use-package rust-mode
        :mode "\\.rs\\'")

      (use-package go-mode
        :mode "\\.go\\'")

      (use-package python-mode
        :mode "\\.py\\'")

      (use-package js2-mode
        :mode "\\.js\\'"
        :config
        (setq js2-basic-offset 2))

      (use-package typescript-mode
        :mode "\\.ts\\'")

      (use-package yaml-mode
        :mode "\\.ya?ml\\'")

      (use-package json-mode
        :mode "\\.json\\'")

      (use-package markdown-mode
        :mode ("\\.md\\'" . markdown-mode)
        :config
        (setq markdown-command "pandoc"))

      ;; Org mode enhancements
      (use-package org
        :config
        (setq org-startup-indented t)
        (setq org-hide-leading-stars t)
        (setq org-src-tab-acts-natively t)
        (setq org-edit-src-content-indentation 0))

      (use-package org-bullets
        :hook (org-mode . org-bullets-mode))

      ;; Visual enhancements
      (use-package rainbow-delimiters
        :hook (prog-mode . rainbow-delimiters-mode))

      (use-package highlight-indent-guides
        :hook (prog-mode . highlight-indent-guides-mode)
        :config
        (setq highlight-indent-guides-method 'character))

      ;; Window management
      (use-package ace-window
        :bind ("M-o" . ace-window))

      ;; Multiple cursors
      (use-package multiple-cursors
        :bind (("C-S-c C-S-c" . mc/edit-lines)
               ("C->" . mc/mark-next-like-this)
               ("C-<" . mc/mark-previous-like-this)
               ("C-c C-<" . mc/mark-all-like-this)))

      ;; Undo tree
      (use-package undo-tree
        :diminish undo-tree-mode
        :config
        (global-undo-tree-mode 1))

      ;; Terminal
      (use-package vterm
        :bind ("C-c t" . vterm))

      ;; Dashboard
      (use-package dashboard
        :config
        (dashboard-setup-startup-hook)
        (setq dashboard-startup-banner 'logo)
        (setq dashboard-items '((recents  . 5)
                              (bookmarks . 5)
                              (projects . 5))))

      ;; Custom key bindings
      (global-set-key (kbd "C-x C-b") 'ibuffer)
      (global-set-key (kbd "M-/") 'hippie-expand)
      (global-set-key (kbd "C-c r") 'revert-buffer)

      ;; Custom functions
      (defun my/reload-emacs-config ()
        "Reload Emacs configuration"
        (interactive)
        (load-file "~/.emacs.d/init.el")
        (message "Configuration reloaded!"))

      (global-set-key (kbd "C-c R") 'my/reload-emacs-config)

      ;; Enable gcmh for better garbage collection
      (use-package gcmh
        :config
        (gcmh-mode 1))

      ;; Helpful for better help
      (use-package helpful
        :bind
        ([remap describe-function] . helpful-function)
        ([remap describe-command] . helpful-command)
        ([remap describe-variable] . helpful-variable)
        ([remap describe-key] . helpful-key))

      ;; Final message
      (message "Emacs configuration loaded successfully!")
    '';
  };

  # Additional packages that work well with Emacs
  home.packages = with pkgs; [
    # Fonts for better Emacs experience
    jetbrains-mono
    fira-code
    source-code-pro

    # Language servers for LSP mode
    nil # Nix LSP
    rust-analyzer # Rust LSP
    gopls # Go LSP
    pyright # Python LSP
    nodePackages.typescript-language-server # TypeScript LSP
    nodePackages.bash-language-server # Bash LSP
    yaml-language-server # YAML LSP

    # Tools for various Emacs packages
    ripgrep # Fast search for Emacs
    fd # Fast find for Emacs
    pandoc # For markdown-mode
    aspell # Spell checking
    aspellDicts.en # English dictionary

    # Git tools
    git

    # Optional: LaTeX for org-mode export
    # texlive.combined.scheme-medium

    # Image viewing (for org-mode images)
    imagemagick

    # PDF tools
    poppler_utils # For PDF handling
  ];

  # Set environment variables for Emacs
  home.sessionVariables = {
    EDITOR = "emacs";
    VISUAL = "emacs";
  };

  # Create Emacs service for daemon mode (optional)
  services.emacs = {
    enable = lib.mkDefault false; # Disabled by default, enable if desired
    client.enable = true;
    defaultEditor = true;
    startWithUserSession = true;
  };

  # XDG configuration for Emacs
  xdg.configFile."emacs/early-init.el".text = ''
    ;; Early init configuration for better startup performance
    (setq gc-cons-threshold most-positive-fixnum)
    (setq gc-cons-percentage 0.6)
    (setq package-enable-at-startup nil)

    ;; UI optimizations
    (push '(menu-bar-lines . 0) default-frame-alist)
    (push '(tool-bar-lines . 0) default-frame-alist)
    (push '(vertical-scroll-bars) default-frame-alist)

    ;; Disable package.el in favor of straight.el or use-package
    (setq package-enable-at-startup nil)
  '';

  # Emacs desktop entry (for better integration)
  xdg.desktopEntries.emacs = lib.mkIf config.programs.emacs.enable {
    name = "Emacs";
    comment = "Edit text";
    icon = "emacs";
    exec = "emacs %F";
    categories = [ "Development" "TextEditor" ];
    mimeType = [
      "text/english"
      "text/plain"
      "text/x-makefile"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
    ];
  };
}
