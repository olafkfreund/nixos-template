# Emacs Configuration

This directory contains a comprehensive Emacs configuration built with Nix and Home Manager. The configuration provides a modern development environment with LSP support, completion frameworks, and productivity enhancements.

## Features

### Core Functionality

- **Modern Completion**: Vertico + Orderless + Marginalia for enhanced completion
- **Search and Navigation**: Consult for powerful search and navigation commands
- **Project Management**: Projectile for project-aware operations
- **Git Integration**: Magit for comprehensive Git operations
- **LSP Support**: Language Server Protocol for multiple programming languages

### Development Environment

- **Syntax Highlighting**: Tree-sitter based highlighting for modern languages
- **Code Completion**: Company mode with LSP backend
- **Syntax Checking**: Flycheck for real-time error detection
- **Snippets**: YASnippet with comprehensive snippet collections
- **Multiple Cursors**: Advanced text editing capabilities

### Supported Languages

- **Nix**: Full support with LSP (nil)
- **Rust**: rust-mode with rust-analyzer
- **Go**: go-mode with gopls
- **Python**: python-mode with pyright
- **JavaScript/TypeScript**: js2-mode and typescript-mode with LSP
- **Web Development**: web-mode for templates
- **Markup**: Markdown, YAML, JSON support
- **Configuration**: Dockerfile, various config formats

### Productivity Features

- **Org-mode**: Enhanced with bullets and better defaults
- **Terminal**: vterm for full-featured terminal emulation
- **File Management**: Enhanced dired with ranger-like operations
- **Window Management**: ace-window for quick window switching
- **Theme**: Doom themes with doom-modeline

## Quick Start

### Enable in User Configuration

Add to your Home Manager configuration:

```nix
# Import Emacs configuration
imports = [
  ../editors/emacs.nix
];
```

### First Launch

1. **Start Emacs**:

   ```bash
   emacs
   ```

2. **Install all-the-icons fonts** (required for UI):
   - Run `M-x all-the-icons-install-fonts` in Emacs
   - Or manually install from the system

3. **LSP Servers**: Language servers are automatically installed via Nix

### Basic Usage

#### Key Bindings

**Global Navigation**:

- `C-s` - Search in buffer (Consult)
- `C-x b` - Switch buffer (Consult)
- `C-x C-f` - Find file
- `M-o` - Switch window (Ace Window)

**Project Management** (Projectile - `C-c p`):

- `C-c p p` - Switch project
- `C-c p f` - Find file in project
- `C-c p s r` - Search in project (ripgrep)
- `C-c p b` - Switch to project buffer

**Git Operations** (Magit):

- `C-x g` - Git status
- In Magit buffer: `s` (stage), `u` (unstage), `c c` (commit)

**LSP Operations** (`C-c l`):

- `C-c l r r` - Rename symbol
- `C-c l g g` - Go to definition
- `C-c l g r` - Find references
- `C-c l a a` - Code actions

**Code Editing**:

- `C->` / `C-<` - Multiple cursors (mark next/previous)
- `M-/` - Expand abbreviation
- `C-c t` - Open terminal (vterm)

#### Completion System

The configuration uses Vertico for completion with:

- **Orderless matching**: Type parts of what you want in any order
- **Marginalia**: Rich annotations showing additional information
- **Consult**: Enhanced versions of common commands

Example: To find a file containing "config" and "emacs":

```
C-x C-f config emacs RET
```

## Customization

### Adding Languages

To add support for a new language:

1. **Add the language mode package**:

```nix
extraPackages = epkgs: with epkgs; [
  # existing packages...
  your-language-mode
];
```

2. **Add LSP server to system packages**:

```nix
home.packages = with pkgs; [
  # existing packages...
  your-language-server
];
```

3. **Configure in extraConfig**:

```elisp
(use-package your-language-mode
  :mode "\\.ext\\'"
  :hook (your-language-mode . lsp))
```

### Changing Theme

Replace the doom-themes configuration:

```elisp
;; Replace this in extraConfig
(use-package doom-themes
  :config
  (load-theme 'doom-dracula t))  ;; Change theme here
```

Available doom themes:

- `doom-one` (default)
- `doom-dracula`
- `doom-nord`
- `doom-tomorrow-night`
- `doom-monokai-pro`

### Adding Custom Packages

Add packages to the `extraPackages` list:

```nix
extraPackages = epkgs: with epkgs; [
  # existing packages...
  package-name
];
```

Then configure in `extraConfig`:

```elisp
(use-package package-name
  :config
  ;; your configuration
  )
```

### Custom Key Bindings

Add to the `extraConfig` section:

```elisp
;; Custom key bindings
(global-set-key (kbd "C-c C-r") 'your-function)
(define-key emacs-lisp-mode-map (kbd "C-c C-e") 'eval-buffer)
```

### Font Configuration

Change the font in `extraConfig`:

```elisp
;; Font configuration
(set-face-attribute 'default nil :font "Your Font-12")
```

Available fonts (installed by configuration):

- JetBrains Mono (default)
- Fira Code
- Source Code Pro

## Advanced Configuration

### Org-mode Setup

The configuration includes basic org-mode enhancements. For advanced org setup:

1. **Enable org-roam** for note-taking:

```elisp
(use-package org-roam
  :custom
  (org-roam-directory "~/org-roam/")
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert))
  :config
  (org-roam-setup))
```

2. **Configure org directories**:

```elisp
(setq org-directory "~/org/")
(setq org-default-notes-file (concat org-directory "/notes.org"))
```

### LSP Performance Tuning

For better LSP performance:

```elisp
(setq lsp-idle-delay 0.5)
(setq lsp-log-io nil)
(setq lsp-restart 'auto-restart)
(setq lsp-enable-symbol-highlighting nil)
(setq lsp-enable-on-type-formatting nil)
```

### Daemon Mode

To use Emacs in daemon mode for faster startup:

1. **Enable the service**:

```nix
services.emacs = {
  enable = true;
  client.enable = true;
  defaultEditor = true;
};
```

2. **Use emacsclient**:

```bash
emacsclient -c    # New frame
emacsclient -t    # Terminal mode
```

## Troubleshooting

### Common Issues

**Fonts not displaying correctly**:

```bash
# Install all-the-icons fonts
M-x all-the-icons-install-fonts
```

**LSP not working**:

1. Check if language server is installed: `which rust-analyzer`
2. Restart LSP: `M-x lsp-workspace-restart`
3. Check LSP logs: `M-x lsp-workspace-show-log`

**Slow startup**:

1. Check package loading: `M-x emacs-init-time`
2. Profile startup: `emacs --debug-init`
3. Consider daemon mode

**Completion not working**:

1. Check if company-mode is enabled: `M-x company-mode`
2. Force completion: `M-x company-complete`
3. Check company backends: `M-x company-diag`

### Performance Issues

**High CPU usage**:

1. Disable unnecessary features:

   ```elisp
   (setq lsp-enable-file-watchers nil)
   (setq lsp-enable-folding nil)
   ```

2. Reduce UI updates:
   ```elisp
   (setq lsp-ui-sideline-enable nil)
   (setq lsp-ui-doc-enable nil)
   ```

**Memory usage**:

1. Tune garbage collection:
   ```elisp
   (setq gc-cons-threshold 20000000)
   (setq gc-cons-percentage 0.1)
   ```

### Debugging

**Enable debug mode**:

```bash
emacs --debug-init
```

**Check configuration**:

```elisp
M-x emacs-version
M-x describe-variable RET user-init-file
```

## Integration with NixOS

### System Integration

The configuration integrates with NixOS/Home Manager by:

1. **Declarative packages**: All packages defined in Nix
2. **Language servers**: Installed via Nix packages
3. **System fonts**: Available system-wide
4. **Desktop integration**: Proper MIME type associations

### Updating Configuration

1. **Edit the configuration**:

   ```bash
   $EDITOR home/editors/emacs.nix
   ```

2. **Test changes**:

   ```bash
   just test hostname
   ```

3. **Apply changes**:

   ```bash
   just switch hostname
   ```

4. **Restart Emacs** to load new configuration

### Version Management

**Update Emacs version**:

```nix
programs.emacs = {
  package = pkgs.emacs29-pgtk;  # Change version here
};
```

**Update packages**: Packages are automatically updated with nixpkgs updates.

## Learning Resources

### Emacs Basics

- [GNU Emacs Manual](https://www.gnu.org/software/emacs/manual/html_node/emacs/)
- [Emacs Tutorial](https://www.gnu.org/software/emacs/tour/) (Built-in: `C-h t`)
- [EmacsWiki](https://www.emacswiki.org/)

### Package Documentation

- [Magit Manual](https://magit.vc/manual/magit/)
- [LSP Mode](https://emacs-lsp.github.io/lsp-mode/)
- [Company Mode](https://company-mode.github.io/)
- [Projectile](https://docs.projectile.mx/projectile/index.html)

### Advanced Topics

- [Org Mode Manual](https://orgmode.org/manual/)
- [Doom Emacs Config](https://github.com/doomemacs/doomemacs) (for inspiration)
- [System Crafters Emacs](https://systemcrafters.net/emacs-essentials/) (video tutorials)

## Contributing

To contribute improvements to this configuration:

1. **Test thoroughly** on multiple systems
2. **Document changes** in this README
3. **Follow Nix conventions** for package management
4. **Maintain backward compatibility** where possible
5. **Add appropriate comments** to elisp code

## Migration from Other Configs

### From Doom Emacs

- Most keybindings work similarly
- Packages may have different names
- Configuration syntax is standard Emacs Lisp

### From Spacemacs

- Switch to Emacs-style keybindings
- Use `which-key` for discovery
- Equivalent packages available

### From VSCode

- LSP provides similar IDE features
- Projectile replaces workspace functionality
- Magit provides superior Git integration
