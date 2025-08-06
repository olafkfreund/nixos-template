{ pkgs, ... }:

with pkgs;
{
  default = mkShell {
    name = "nixos-config";

    buildInputs = [
      # Nix tools
      nixpkgs-fmt
      nil # Nix LSP
      nix-output-monitor # Better nix build output
      nix-tree # Visualize Nix dependencies

      # Code quality tools
      statix # Nix linter and code analyzer
      deadnix # Dead code detection
      vulnix # Security vulnerability scanner

      # Build tools
      just # Task runner
      git

      # Secrets management
      sops
      ssh-to-pgp

      # Documentation
      mdbook

      # System utilities
      pciutils
      usbutils

      # Development utilities
      fd # Better find
      ripgrep # Better grep
      bat # Better cat
      eza # Better ls
      fzf # Fuzzy finder

      # Git hooks and automation
      pre-commit # Git pre-commit hooks
    ];

    shellHook = ''
      echo "🚀 NixOS Configuration Development Environment"
      echo ""
      echo "📋 Basic Commands:"
      echo "  just switch      - Rebuild and switch to new configuration"
      echo "  just test        - Test configuration without switching"
      echo "  just boot        - Build configuration for next boot"
      echo "  just update      - Update flake inputs"
      echo ""
      echo "🔍 Code Quality:"
      echo "  just validate    - Run comprehensive validation (check, lint, format)"
      echo "  just quality     - Full code quality suite (includes security audit)"
      echo "  just fmt         - Format Nix files"
      echo "  just check       - Check flake for errors"
      echo "  just lint        - Lint Nix code with statix"
      echo "  just dead-code-check - Check for unused code"
      echo "  just security-audit  - Run security vulnerability scan"
      echo ""
      echo "🖥️  Desktop Management:"
      echo "  just list-desktops   - Show available desktop environments"
      echo "  just test-desktop DE - Test specific desktop configuration"
      echo "  just niri-keys       - Show Niri keybindings (if using Niri)"
      echo ""
      echo "👤 User Templates:"
      echo "  just list-users      - Show available user templates"
      echo "  just init-user HOST TEMPLATE - Initialize user config from template"
      echo "  just show-user TEMPLATE      - Show template details"
      echo ""
      echo "🔧 Development Setup:"
      echo "  just dev-setup       - Complete development environment setup"
      echo "  just install-hooks   - Install git pre-commit hooks"
      echo "  just run-hooks       - Run hooks on all files"
      echo ""
      echo "📚 More commands: just --list"
      echo ""
      
      # Check if this is a new setup
      if [[ ! -f .git/hooks/pre-commit ]]; then
        echo "💡 TIP: Run 'just dev-setup' to configure git hooks and validation"
        echo ""
      fi
    '';
  };
}
