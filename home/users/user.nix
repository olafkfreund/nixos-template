{ config, pkgs, ... }:

{
  # Basic Home Manager configuration for default user

  # Import desktop profile (change based on your desktop environment)

  # Basic user information
  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "25.05";
  };

  # Program configurations
  programs = {
    # Let Home Manager manage itself
    home-manager.enable = true;

    # Git configuration
    git = {
      enable = true;
      userName = "User Name";
      userEmail = "user@example.com";

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "nano";
      };
    };

    # Shell configuration
    bash = {
      enable = true;

      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";

        # NixOS specific aliases
        rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
        rebuild-test = "sudo nixos-rebuild test --flake ~/nixos-config";
        update = "nix flake update ~/nixos-config";
      };

      bashrcExtra = ''
        # Custom prompt
        export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ "
        
        # History settings
        export HISTSIZE=10000
        export HISTFILESIZE=20000
        export HISTCONTROL=ignoredups:erasedups
      '';
    };

    # Better command line tools
    eza = {
      enable = true;
      aliases = {
        ls = "eza";
        ll = "eza -l";
        la = "eza -la";
        tree = "eza --tree";
      };
    };

    # Better cat
    bat.enable = true;

    # Better find
    fd.enable = true;

    # Better grep
    ripgrep.enable = true;

    # System monitoring
    htop.enable = true;
    btop.enable = true;

    # Directory navigation
    zoxide.enable = true;

    # SSH configuration
    ssh = {
      enable = true;

      matchBlocks = {
        "example-server" = {
          hostname = "server.example.com";
          user = "user";
          # identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };

  # Import shared package sets
  imports = [
    # Choose your desktop profile
    ../profiles/gnome.nix
    # ../profiles/kde.nix
    # ../profiles/hyprland.nix
    # ../profiles/niri.nix
    
    # Shared package sets
    ../packages/core-system.nix
  ];

  # XDG directories
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nano";
    BROWSER = "firefox";
    TERMINAL = "gnome-terminal";
  };
}
