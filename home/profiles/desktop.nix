# Desktop Home Manager profile
# Configuration for desktop/workstation environments with GUI applications
{ lib, pkgs, ... }:

{
  # Import base configuration
  imports = [ ./base.nix ];

  # Override defaults for desktop environment
  # Consolidated home and programs configuration
  home = {
    sessionVariables.TERMINAL = lib.mkDefault "alacritty";

    # Desktop applications
    packages = with pkgs; [
      # Browsers
      firefox
      chromium

      # Media
      vlc
      mpv

      # Graphics and design
      gimp
      inkscape

      # Office suite
      libreoffice

      # Development
      vscode

      # Communication
      discord
      telegram-desktop

      # Utilities
      flameshot # Screenshots
      copyq # Clipboard manager

      # Archive tools
      p7zip
      unrar

      # System monitoring
      htop
      neofetch
    ];

  };

  # Programs configuration consolidated
  programs = {
    # Override base profile's zsh.enable = false
    zsh.enable = true;

    # Terminal emulator configuration
    alacritty = {
      enable = lib.mkDefault true;

      settings = {
        window = {
          padding = { x = 8; y = 8; };
          decorations = "full";
          startup_mode = "Windowed";
        };

        scrolling = {
          history = 10000;
          multiplier = 3;
        };

        font = {
          normal = {
            family = "JetBrains Mono Nerd Font";
            style = "Regular";
          };
          size = 12.0;
        };

        colors = {
          primary = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
          };

          cursor = {
            text = "#1e1e2e";
            cursor = "#f5e0dc";
          };
        };

        selection.save_to_clipboard = true;

        shell = {
          program = "${pkgs.zsh}/bin/zsh";
          args = [ "-l" ];
        };
      };
    };

    # Desktop file associations
    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "application/pdf" = "firefox.desktop";
        "image/jpeg" = "gimp.desktop";
        "image/png" = "gimp.desktop";
        "image/gif" = "gimp.desktop";
        "video/mp4" = "vlc.desktop";
        "video/x-matroska" = "vlc.desktop";
        "audio/mpeg" = "vlc.desktop";
        "audio/flac" = "vlc.desktop";
      };
    };

    # Desktop-specific shell aliases
    bash.shellAliases = {
      # Screenshot utilities
      screenshot = "flameshot gui";
      screenshot-full = "flameshot full -p ~/Pictures/Screenshots/";

      # Quick application launches
      code = "code .";

      # System information
      sysinfo = "neofetch";

      # Package management
      update-system = "sudo nixos-rebuild switch";
      update-home = "home-manager switch";

      # Development shortcuts
      serve-here = "python3 -m http.server 8000";

      # Docker shortcuts (if docker is available)
      dps = "docker ps";
      dim = "docker images";
      dex = "docker exec -it";
    };

    zsh.shellAliases = {
      # Inherit bash aliases
      screenshot = "flameshot gui";
      screenshot-full = "flameshot full -p ~/Pictures/Screenshots/";
      code = "code .";
      sysinfo = "neofetch";
      update-system = "sudo nixos-rebuild switch";
      update-home = "home-manager switch";
      serve-here = "python3 -m http.server 8000";
      dps = "docker ps";
      dim = "docker images";
      dex = "docker exec -it";
    };

    # Git configuration for desktop development
    git.extraConfig = {
      # Enhanced diff and merge tools for GUI environments
      diff.tool = "vscode";
      merge.tool = "vscode";
      difftool.vscode.cmd = "code --wait --diff $LOCAL $REMOTE";
      mergetool.vscode.cmd = "code --wait $MERGED";

      # Desktop-specific settings
      core.autocrlf = false;
      gui.recentrepo = true;
    };
  };

  # Desktop environment services
  services = {
    # Clipboard manager
    copyq.enable = lib.mkDefault false; # Enable if desired

    # Network manager applet (for desktop environments that need it)
    network-manager-applet.enable = lib.mkDefault false; # Enable if needed

    # Bluetooth applet
    blueman-applet.enable = lib.mkDefault false; # Enable if needed
  };

  # Fonts for desktop environment
  fonts.fontconfig.enable = true;
}
