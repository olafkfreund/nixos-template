# nix-darwin Configuration
# Main entry point for macOS system configuration

{ config, pkgs, lib, inputs, outputs, ... }:

{
  imports = [
    ./system.nix
    ./homebrew.nix
    ./networking.nix
    ./security.nix
  ];

  # System identification
  networking.hostName = lib.mkDefault "nixos-darwin";
  networking.localHostName = lib.mkDefault "nixos-darwin";

  # Enable Nix daemon
  services.nix-daemon.enable = true;

  # Nix configuration
  nix = {
    # Enable flakes and new command
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@admin" ];

      # Substituters and keys
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # Build settings
      max-jobs = "auto";
      cores = 0;

      # Optimize store
      auto-optimise-store = true;
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 14d";
    };

    # Linux builder for cross-compilation
    linux-builder = {
      enable = true;
      ephemeral = true;
      maxJobs = 4;
      config = {
        virtualisation = {
          darwin-builder = {
            diskSize = 30 * 1024; # 30GB
            memorySize = 8 * 1024; # 8GB
          };
          cores = 6;
        };
      };
    };
  };

  # nixpkgs configuration
  nixpkgs = {
    config = {
      allowUnfree = true;
      # allowBroken = false;
      # allowInsecure = false;
    };

    # Apply overlays
    overlays = [
      # Custom overlays from the template
      outputs.overlays.modifications
      outputs.overlays.additions

      # Add any additional overlays here
    ];
  };

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    vim
    git
    curl
    wget

    # Development tools
    just
    direnv

    # System utilities
    htop
    tree

    # Nix tools
    nixpkgs-fmt
    statix
    deadnix

    # macOS-specific utilities
    (writeShellScriptBin "darwin-rebuild-switch" ''
      darwin-rebuild switch --flake ~/.config/nix-darwin#$(hostname -s)
    '')

    (writeShellScriptBin "update-darwin" ''
      cd ~/.config/nix-darwin
      nix flake update
      darwin-rebuild switch --flake .#$(hostname -s)
    '')

    (writeShellScriptBin "darwin-info" ''
      echo "=== nix-darwin System Information ==="
      echo "Hostname: $(hostname)"
      echo "Architecture: $(uname -m)"
      echo "macOS Version: $(sw_vers -productVersion)"
      echo "Darwin Generation: $(darwin-rebuild --list-generations | tail -1)"
      echo "Nix Version: $(nix --version)"
      echo ""
      echo "Home Manager Status:"
      if command -v home-manager >/dev/null; then
        echo "  Installed: Yes"
        home-manager generations | head -3
      else
        echo "  Installed: No"
      fi
      echo ""
      echo "Nix Store:"
      du -sh /nix/store 2>/dev/null || echo "  Unable to access /nix/store"
      echo ""
      echo "System Packages:"
      nix-env -q --installed --profile /nix/var/nix/profiles/system | head -10
    '')
  ];

  # Shell configuration
  programs = {
    # Zsh as default shell with nix integration
    zsh = {
      enable = true;
      enableCompletion = true;
      enableBashCompletion = true;

      # Shell initialization
      shellInit = ''
        # Nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        # Direnv with validation
        if command -v direnv >/dev/null; then
          direnv_hook="$(direnv hook zsh 2>/dev/null || echo "")"
          if [[ -n "$direnv_hook" && "$direnv_hook" =~ ^[[:space:]]*direnv ]]; then
            eval "$direnv_hook"
          fi
        fi

        # Add Homebrew to PATH (if using Homebrew) with validation
        if [ -f /opt/homebrew/bin/brew ]; then
          brew_env="$(/opt/homebrew/bin/brew shellenv 2>/dev/null || echo "")"
          if [[ -n "$brew_env" && "$brew_env" =~ export.*HOMEBREW ]]; then
            eval "$brew_env"
          fi
        elif [ -f /usr/local/bin/brew ]; then
          brew_env="$(/usr/local/bin/brew shellenv 2>/dev/null || echo "")"
          if [[ -n "$brew_env" && "$brew_env" =~ export.*HOMEBREW ]]; then
            eval "$brew_env"
          fi
        fi
      '';

      # Interactive shell configuration
      interactiveShellInit = ''
          # Set up aliases
          alias darwin-rebuild="darwin-rebuild --flake ~/.config/nix-darwin"
          alias nix-rebuild="darwin-rebuild switch --flake ~/.config/nix-darwin#$(hostname -s)"
        alias nix-update="cd ~/.config/nix-darwin && nix flake update && darwin-rebuild switch --flake .#$(hostname -s)"

        # Development aliases
        alias ll="ls -la"
        alias la="ls -la"
        alias ..="cd .."
        alias ...="cd ../.."

        # Nix aliases
        alias nix-search="nix search nixpkgs"
        alias nix-shell="nix-shell --run zsh"
        alias nix-info="nix-shell -p nix-info --run nix-info"

        # System aliases
        alias macos-info="darwin-info"

        echo "🍎 Welcome to nix-darwin!"
        echo "Run 'darwin-info' for system information"
      '';
    };

    # Fish shell support (optional)
    fish.enable = true;

    # Bash completion
    bash.enableCompletion = true;
  };

  # Set up shells
  environment.shells = with pkgs; [ bash zsh fish ];

  # System settings
  system = {
    # Darwin system version
    stateVersion = 5;

    # Activate system configuration
    activationScripts.preActivation.text = ''
      echo "Activating nix-darwin configuration..."
      echo "Hostname: $(hostname)"
      echo "User: $(whoami)"
      echo "Architecture: $(uname -m)"
    '';

    # Post-activation scripts
    activationScripts.postActivation.text = ''
      echo "nix-darwin activation complete!"
      echo ""
      echo "Next steps:"
      echo "  • Run 'darwin-info' for system information"
      echo "  • Configure Home Manager if not already done"
      echo "  • Rebuild with: darwin-rebuild switch --flake ~/.config/nix-darwin"
    '';
  };

  # Fonts
  fonts = {
    packages = with pkgs; [
      # Programming fonts
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Hack" ]; })

      # System fonts
      inter
      source-code-pro
      source-sans-pro
      source-serif-pro
    ];
  };

  # Services
  services = {
    # Automatic store optimization enabled via services.nix-daemon.enable above

    # Lorri for direnv integration (optional)
    # lorri.enable = true;
  };

  # User configuration placeholder
  # This will be overridden in specific host configurations
  users.users = lib.mkDefault { };

  # Home Manager integration placeholder
  # This will be configured in flake.nix or host-specific configs
}

