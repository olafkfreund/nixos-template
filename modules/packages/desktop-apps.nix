# Desktop applications package collection
# GUI applications commonly used on desktop/workstation systems
{
  pkgs,
  lib,
  config,
  ...
}:

{
  options.modules.packages.desktop-apps = {
    enable = lib.mkEnableOption "desktop applications package collection";

    includeGames = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include gaming applications and Steam";
    };

    includeMultimedia = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include multimedia applications";
    };

    includeGraphics = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include graphics and design applications";
    };

    includeOffice = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include office suite applications";
    };
  };

  config = lib.mkIf config.modules.packages.desktop-apps.enable {
    environment.systemPackages =
      with pkgs;
      [
        # Web browsers
        firefox

        # Communication
        discord
        telegram-desktop

        # File managers and utilities.
        # One per job: the GNOME and KDE modules install their own desktop's
        # apps, so this DE-neutral collection deliberately does not ship a
        # second file manager, terminal, viewer or browser alongside them.
        thunar # Lightweight, desktop-agnostic file manager
        file-roller # Archive manager
        gparted # Partition manager

        # Terminal emulator (matches the default used by the Hyprland and
        # niri profiles, so a user only learns one)
        alacritty

        # Graphical text editor
        gnome-text-editor # GNOME's current editor; replaced gedit as the default

        # System utilities
        flameshot # Screenshots
        copyq # Clipboard manager
        keepassxc # Password manager

        # Network tools
        wireshark

      ]
      ++ lib.optionals config.modules.packages.desktop-apps.includeMultimedia [
        # Media players
        vlc

        # Audio
        audacity
        pavucontrol # PulseAudio volume control

        # Video editing and conversion
        kdenlive
        handbrake

        # Streaming
        obs-studio

      ]
      ++ lib.optionals config.modules.packages.desktop-apps.includeGraphics [
        # Graphics and design
        gimp
        inkscape
        krita
        blender

        # Image viewer
        loupe # GNOME's current viewer; replaced eog as the default in GNOME 45

        # CAD and 3D
        freecad

      ]
      ++ lib.optionals config.modules.packages.desktop-apps.includeOffice [
        # Office suite
        libreoffice-fresh

        # PDF viewer
        papers # The continuation of evince, renamed in GNOME 46

        # Email
        thunderbird

        # Note taking
        obsidian

        # Productivity
        calibre # E-book management

      ]
      ++ lib.optionals config.modules.packages.desktop-apps.includeGames [
        # Gaming
        steam
        lutris
        gamemode

        # Emulators
        retroarch

        # Game tools
        mangohud # Performance overlay
      ];

    # Desktop-specific system configuration

    # Fonts for desktop applications
    fonts = {
      enableDefaultPackages = true;

      packages = with pkgs; [
        # Programming fonts
        jetbrains-mono
        fira-code

        # System fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji

        # Popular fonts
        liberation_ttf
        dejavu_fonts

        # Icon fonts
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.dejavu-sans-mono
      ];

      fontconfig = {
        enable = true;

        defaultFonts = {
          serif = [
            "DejaVu Serif"
            "Noto Serif"
          ];
          sansSerif = [
            "DejaVu Sans"
            "Noto Sans"
          ];
          monospace = [
            "JetBrains Mono"
            "DejaVu Sans Mono"
          ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    # XDG portal for desktop integration
    xdg.portal = {
      enable = lib.mkDefault true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-kde
      ];

      # xdg-desktop-portal 1.17+ requires an explicit backend preference;
      # without this it warns and falls back to lexicographical order.
      config.common.default = lib.mkDefault [ "gtk" ];
    };

    # Common desktop services
    services = {
      # Audio
      pulseaudio.enable = lib.mkDefault false; # Use PipeWire instead
      pipewire = {
        enable = lib.mkDefault true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = lib.mkDefault false;
      };

      # Printing
      printing.enable = lib.mkDefault true;

      # Bluetooth
      blueman.enable = lib.mkDefault true;

      # Network discovery
      avahi = {
        enable = lib.mkDefault true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    # Hardware support for desktop
    hardware = {
      graphics = {
        enable = lib.mkDefault true;
        enable32Bit = lib.mkDefault (pkgs.stdenv.system == "x86_64-linux");
      };

      pulseaudio.enable = lib.mkDefault false; # Use PipeWire
      bluetooth.enable = lib.mkDefault true;
    };

    # Security for desktop applications
    security = {
      polkit.enable = lib.mkDefault true;
      rtkit.enable = lib.mkDefault true; # For PipeWire
    };

    # Desktop-friendly firewall rules
    networking.firewall = {
      # Allow common desktop protocols
      allowedTCPPorts = lib.optionals config.services.avahi.enable [ 5353 ];
      allowedUDPPorts = lib.optionals config.services.avahi.enable [ 5353 ];
    };
  };
}
