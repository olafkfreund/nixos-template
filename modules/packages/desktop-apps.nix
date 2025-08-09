# Desktop applications package collection
# GUI applications commonly used on desktop/workstation systems
{ pkgs, lib, config, ... }:

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
    environment.systemPackages = with pkgs; [
      # Web browsers
      firefox
      chromium

      # Communication
      discord
      telegram-desktop

      # File managers and utilities
      dolphin # KDE file manager
      thunar # XFCE file manager
      file-roller # Archive manager
      gparted # Partition manager

      # Terminal emulators
      alacritty
      kitty

      # Text editors
      kate
      gedit

      # System utilities
      flameshot # Screenshots
      copyq # Clipboard manager
      keepassxc # Password manager

      # Network tools
      wireshark

    ] ++ lib.optionals config.modules.packages.desktop-apps.includeMultimedia [
      # Media players
      vlc
      mpv

      # Audio
      audacity
      pavucontrol # PulseAudio volume control

      # Video editing and conversion
      kdenlive
      handbrake

      # Streaming
      obs-studio

    ] ++ lib.optionals config.modules.packages.desktop-apps.includeGraphics [
      # Graphics and design
      gimp
      inkscape
      krita
      blender

      # Image viewers
      gwenview # KDE image viewer
      eog # GNOME image viewer

      # CAD and 3D
      freecad

    ] ++ lib.optionals config.modules.packages.desktop-apps.includeOffice [
      # Office suite
      libreoffice-fresh

      # PDF viewers and tools
      okular # KDE PDF viewer
      evince # GNOME PDF viewer

      # Email
      thunderbird

      # Note taking
      obsidian

      # Productivity
      calibre # E-book management

    ] ++ lib.optionals config.modules.packages.desktop-apps.includeGames [
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
        noto-fonts-emoji

        # Popular fonts
        liberation_ttf
        dejavu_fonts

        # Icon fonts
        (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "DejaVuSansMono" ]; })
      ];

      fontconfig = {
        enable = true;

        defaultFonts = {
          serif = [ "DejaVu Serif" "Noto Serif" ];
          sansSerif = [ "DejaVu Sans" "Noto Sans" ];
          monospace = [ "JetBrains Mono" "DejaVu Sans Mono" ];
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
