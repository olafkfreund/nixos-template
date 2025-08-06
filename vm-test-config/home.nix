{ config, pkgs, ... }:

{
  # Home Manager configuration for desktop user

  # Import desktop-specific profiles (uncomment the one matching your desktop)
  imports = [
    # GNOME Desktop Profile (default)
    ../../home/profiles/gnome.nix

    # KDE Desktop Profile
    # ../../home/profiles/kde.nix

    # Hyprland Tiling WM Profile
    # ../../home/profiles/hyprland.nix

    # Niri Scrollable Tiling WM Profile
    # ../../home/profiles/niri.nix
  ];

  # Basic user info
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
      userName = "Your Name";
      userEmail = "your.email@example.com";

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
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
      '';
    };
    # Better ls
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
  };

  # User packages
  home.packages = with pkgs; [
    # Desktop applications
    firefox
    thunderbird
    libreoffice

    # Media
    vlc
    gimp

    # Development tools
    vscode

    # System utilities
    file
    which
    tree
    curl
    wget
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
    };
  };

  # GTK theme configuration
  gtk = {
    enable = true;

    theme = {
      package = pkgs.adwaita-qt;
      name = "Adwaita";
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };
}
