{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.kde;
in
{
  options.modules.desktop.kde = {
    enable = lib.mkEnableOption "KDE Plasma desktop environment";

    # Plasma version
    version = lib.mkOption {
      type = lib.types.enum [ "plasma5" "plasma6" ];
      default = "plasma6";
      description = "KDE Plasma version to use";
    };

    # KDE applications
    applications = {
      enable = lib.mkEnableOption "KDE application suite" // { default = true; };
      minimal = lib.mkEnableOption "minimal KDE applications only";
      office = lib.mkEnableOption "LibreOffice integration";
      multimedia = lib.mkEnableOption "KDE multimedia applications";
      development = lib.mkEnableOption "KDE development tools";
    };

    # Customization options
    theme = {
      enable = lib.mkEnableOption "custom KDE theming" // { default = true; };
      darkMode = lib.mkEnableOption "dark theme by default" // { default = true; };
      wallpaper = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to custom wallpaper";
      };
    };

    # Performance optimizations
    performance = {
      compositor = lib.mkOption {
        type = lib.types.enum [ "opengl" "xrender" "auto" ];
        default = "auto";
        description = "KDE compositor backend";
      };
      animations = lib.mkEnableOption "desktop animations" // { default = true; };
      effects = lib.mkEnableOption "desktop effects" // { default = true; };
    };

    # Wayland support
    wayland = {
      enable = lib.mkEnableOption "Wayland session support" // { default = true; };
      defaultSession = lib.mkEnableOption "use Wayland as default session";
    };
  };

  config = lib.mkIf cfg.enable {
    # Services configuration
    services = {
      # X11 and display manager
      xserver = {
        enable = true;

        # Display manager
        displayManager = {
          sddm = {
            enable = true;
            wayland.enable = cfg.wayland.enable;

            # SDDM theme configuration
            theme = lib.mkIf cfg.theme.enable "breeze";

            settings = lib.mkMerge [
              {
                Theme = {
                  Current = "breeze";
                  CursorTheme = "breeze_cursors";
                };
              }
              (lib.mkIf (!cfg.performance.animations) {
                Theme = {
                  EnableAvatars = "false";
                  DisableAnimations = "true";
                };
              })
            ];
          };

          # Default session
          defaultSession = lib.mkIf cfg.wayland.defaultSession "plasma";
        };

        # Desktop environment
        desktopManager.plasma5.enable = cfg.version == "plasma5";
      };

      # Plasma 6 configuration (when available)
      desktopManager.plasma6.enable = cfg.version == "plasma6";

      # KDE services
      accounts-daemon.enable = true;
      upower.enable = true;

      # Printing support with KDE integration
      printing.enable = true;

      # Scanner support
      saned.enable = true;

      # Bluetooth with KDE integration
      blueman.enable = false; # Use KDE Bluetooth instead
    };

    # Programs configuration
    programs = {
      # KDE Connect for device integration
      kdeconnect.enable = true;

      # Partition manager
      partition-manager.enable = true;

      # File manager
      thunar.enable = false; # Use Dolphin instead
    };

    # Hardware support
    hardware = {
      bluetooth.enable = true;
      pulseaudio.enable = false; # Use PipeWire with KDE
    };

    # Environment configuration
    environment = {
      # Essential KDE applications
      systemPackages = with pkgs; [
        # Core KDE applications (always installed)
        dolphin # File manager
        konsole # Terminal
        kate # Text editor
        spectacle # Screenshot tool
        gwenview # Image viewer
        okular # Document viewer
        ark # Archive manager

        # System utilities
        kdePackages.partitionmanager # Partition manager
        kdePackages.kinfocenter # System information
        kdePackages.systemsettings # System settings

        # KDE theming
        kdePackages.breeze # Breeze theme
        kdePackages.breeze-icons # Breeze icons

      ] ++ lib.optionals (!cfg.applications.minimal) [
        # Extended KDE applications
        kdePackages.kmail # Email client
        kdePackages.kontact # PIM suite
        kdePackages.korganizer # Calendar
        kdePackages.kaddressbook # Address book
        kdePackages.knotes # Notes
        kdePackages.kfind # File search
        kdePackages.kcalc # Calculator
        kdePackages.kcharselect # Character selector

      ] ++ lib.optionals cfg.applications.multimedia [
        # Multimedia applications
        kdePackages.kdenlive # Video editor
        kdePackages.krita # Digital painting
        kdePackages.elisa # Music player
        kdePackages.kamoso # Camera app
        kdePackages.dragon # Video player

      ] ++ lib.optionals cfg.applications.development [
        # Development tools
        kdePackages.kdevelop # IDE
        kdePackages.kompare # Diff viewer
        kdePackages.umbrello # UML modeler

      ] ++ lib.optionals cfg.applications.office [
        # Office applications
        libreoffice-qt # LibreOffice with Qt integration
        kdePackages.kmail # Email integration
      ];

      # Remove unwanted applications
      plasma5.excludePackages = lib.mkIf cfg.applications.minimal (with pkgs; [
        kdePackages.elisa # Music player
        kdePackages.khelpcenter # Help center
        kdePackages.konsole # Keep terminal
        # Add more packages to exclude for minimal install
      ]);
    };

    # Fonts for better KDE experience
    fonts.packages = with pkgs; [
      # KDE fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf

      # Additional fonts for better rendering
      dejavu_fonts
      ubuntu_font_family
    ];

    # XDG portal configuration for better app integration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-kde
      ];

      # Configure portal backends
      config = {
        common = {
          default = [ "kde" ];
        };
        kde = {
          default = [ "kde" "gtk" ];
        };
      };
    };

    # KDE configuration management (dconf auto-enabled by KDE)

    # Session variables for KDE
    environment.sessionVariables = lib.mkMerge [
      # Common KDE variables
      {
        # Qt theming
        QT_QPA_PLATFORMTHEME = "kde";
        QT_STYLE_OVERRIDE = "breeze";

        # KDE session type
        XDG_SESSION_TYPE = if cfg.wayland.defaultSession then "wayland" else "x11";
        XDG_CURRENT_DESKTOP = "KDE";
      }

      # Wayland-specific variables
      (lib.mkIf cfg.wayland.enable {
        # Qt Wayland support
        QT_QPA_PLATFORM = "wayland;xcb"; # Fallback to X11 if needed
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

        # KDE Wayland session
        KWIN_COMPOSE = lib.mkIf (cfg.performance.compositor != "auto") cfg.performance.compositor;
      })
    ];

    # Performance optimizations (settings merged above in sddm configuration)

    # Security and permissions
    security = {
      # KDE Wallet
      pam.services.kwallet = {
        name = "kwallet";
        enableKwallet = true;
      };

      # PolicyKit for KDE
      polkit.enable = true;
    };

    # System groups for KDE functionality
    users.groups = {
      networkmanager = { }; # For network management
    };

    # NetworkManager (managed by core networking)
    networking.networkmanager.packages = with pkgs; [
      networkmanager-openvpn
      networkmanager-openconnect
    ];

    # Audio handled by audio.nix module

    # Assertions to prevent conflicts
    assertions = [
      {
        assertion = !(cfg.enable && config.modules.desktop.gnome.enable);
        message = "Cannot enable both KDE and GNOME desktop environments";
      }
      {
        assertion = !(cfg.enable && config.modules.desktop.hyprland.enable);
        message = "Cannot enable both KDE and Hyprland desktop environments";
      }
    ];
  };
}
