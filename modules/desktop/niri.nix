{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.desktop.niri;
in
{
  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "Niri scrollable-tiling compositor";

    # Niri configuration
    settings = {
      # Input configuration
      input = {
        keyboard = {
          xkb = lib.mkOption {
            type = lib.types.submodule {
              options = {
                layout = lib.mkOption {
                  type = lib.types.str;
                  default = "us";
                  description = "Keyboard layout";
                };
                variant = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Keyboard layout variant";
                };
                options = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "XKB options";
                };
              };
            };
            default = { };
          };

          repeat-delay = lib.mkOption {
            type = lib.types.int;
            default = 600;
            description = "Keyboard repeat delay in milliseconds";
          };

          repeat-rate = lib.mkOption {
            type = lib.types.int;
            default = 25;
            description = "Keyboard repeat rate";
          };
        };

        mouse = {
          natural-scroll = lib.mkEnableOption "natural scrolling" // {
            default = false;
          };
          accel-speed = lib.mkOption {
            type = lib.types.float;
            default = 0.0;
            description = "Mouse acceleration speed";
          };
          accel-profile = lib.mkOption {
            type = lib.types.enum [
              "flat"
              "adaptive"
            ];
            default = "adaptive";
            description = "Mouse acceleration profile";
          };
        };

        touchpad = {
          tap = lib.mkEnableOption "tap to click" // {
            default = true;
          };
          dwt = lib.mkEnableOption "disable while typing" // {
            default = true;
          };
          natural-scroll = lib.mkEnableOption "natural scrolling for touchpad" // {
            default = true;
          };
          click-method = lib.mkOption {
            type = lib.types.enum [
              "button-areas"
              "clickfinger"
            ];
            default = "clickfinger";
            description = "Touchpad click method";
          };
        };
      };

      # Output configuration
      outputs = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Output name (e.g., DP-1, HDMI-A-1)";
              };
              mode = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.submodule {
                    options = {
                      width = lib.mkOption {
                        type = lib.types.int;
                        description = "Screen width";
                      };
                      height = lib.mkOption {
                        type = lib.types.int;
                        description = "Screen height";
                      };
                      refresh = lib.mkOption {
                        type = lib.types.float;
                        description = "Refresh rate";
                      };
                    };
                  }
                );
                default = null;
                description = "Output mode configuration";
              };
              scale = lib.mkOption {
                type = lib.types.float;
                default = 1.0;
                description = "Output scale factor";
              };
              transform = lib.mkOption {
                type = lib.types.enum [
                  "normal"
                  "90"
                  "180"
                  "270"
                  "flipped"
                  "flipped-90"
                  "flipped-180"
                  "flipped-270"
                ];
                default = "normal";
                description = "Output transformation";
              };
              position = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.submodule {
                    options = {
                      x = lib.mkOption {
                        type = lib.types.int;
                        description = "X position";
                      };
                      y = lib.mkOption {
                        type = lib.types.int;
                        description = "Y position";
                      };
                    };
                  }
                );
                default = null;
                description = "Output position";
              };
            };
          }
        );
        default = [ ];
        description = "Output configurations";
      };

      # Layout configuration
      layout = {
        gaps = lib.mkOption {
          type = lib.types.int;
          default = 16;
          description = "Gap size between windows";
        };

        center-focused-column = lib.mkOption {
          type = lib.types.enum [
            "never"
            "always"
            "on-overflow"
          ];
          default = "on-overflow";
          description = "When to center the focused column";
        };

        preset-column-widths = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                proportion = lib.mkOption {
                  type = lib.types.float;
                  description = "Width as proportion of screen width";
                };
              };
            }
          );
          default = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];
          description = "Preset column width proportions";
        };

        default-column-width = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                proportion = lib.mkOption {
                  type = lib.types.float;
                  description = "Default width as proportion of screen width";
                };
              };
            }
          );
          default = {
            proportion = 0.5;
          };
          description = "Default column width";
        };
      };

      # Window rules
      window-rules = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              matches = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      app-id = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Match application ID";
                      };
                      title = lib.mkOption {
                        type = lib.types.nullOr lib.types.str;
                        default = null;
                        description = "Match window title";
                      };
                    };
                  }
                );
                description = "Window matching criteria";
              };

              default-column-width = lib.mkOption {
                type = lib.types.nullOr (
                  lib.types.submodule {
                    options = {
                      proportion = lib.mkOption {
                        type = lib.types.float;
                        description = "Width proportion";
                      };
                    };
                  }
                );
                default = null;
                description = "Default column width for matching windows";
              };

              open-on-output = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Output to open window on";
              };

              open-maximized = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
                description = "Open window maximized";
              };

              open-fullscreen = lib.mkOption {
                type = lib.types.nullOr lib.types.bool;
                default = null;
                description = "Open window fullscreen";
              };
            };
          }
        );
        default = [ ];
        description = "Window rules for specific applications";
      };

      # Appearance
      prefer-no-csd = lib.mkEnableOption "prefer server-side decorations" // {
        default = false;
      };

      hotkey-overlay = {
        skip-at-startup = lib.mkEnableOption "skip hotkey overlay at startup" // {
          default = false;
        };
      };

      screenshot-path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path for screenshots (null for clipboard)";
      };
    };

    # Waybar configuration
    waybar = {
      enable = lib.mkEnableOption "Waybar status bar" // {
        default = true;
      };
      position = lib.mkOption {
        type = lib.types.enum [
          "top"
          "bottom"
        ];
        default = "top";
        description = "Waybar position";
      };

      modules = {
        workspaces = lib.mkEnableOption "workspace indicator" // {
          default = true;
        };
        window = lib.mkEnableOption "window title" // {
          default = true;
        };
        clock = lib.mkEnableOption "clock widget" // {
          default = true;
        };
        battery = lib.mkEnableOption "battery widget" // {
          default = true;
        };
        network = lib.mkEnableOption "network widget" // {
          default = true;
        };
        pulseaudio = lib.mkEnableOption "audio widget" // {
          default = true;
        };
        tray = lib.mkEnableOption "system tray" // {
          default = true;
        };
      };

      theme = lib.mkOption {
        type = lib.types.enum [
          "default"
          "minimal"
          "niri"
        ];
        default = "niri";
        description = "Waybar theme style";
      };
    };

    # Dunst notification daemon
    dunst = {
      enable = lib.mkEnableOption "Dunst notification daemon" // {
        default = true;
      };

      settings = {
        urgency_low = {
          timeout = lib.mkOption {
            type = lib.types.int;
            default = 5;
            description = "Timeout for low urgency notifications";
          };
        };

        urgency_normal = {
          timeout = lib.mkOption {
            type = lib.types.int;
            default = 10;
            description = "Timeout for normal urgency notifications";
          };
        };

        urgency_critical = {
          timeout = lib.mkOption {
            type = lib.types.int;
            default = 0;
            description = "Timeout for critical notifications (0 = no timeout)";
          };
        };
      };
    };

    # Applications and utilities
    applications = {
      terminal = lib.mkOption {
        type = lib.types.str;
        default = "alacritty";
        description = "Default terminal application";
      };

      launcher = lib.mkOption {
        type = lib.types.str;
        default = "fuzzel";
        description = "Application launcher (fuzzel works well with niri)";
      };

      fileManager = lib.mkOption {
        type = lib.types.str;
        default = "thunar";
        description = "Default file manager";
      };

      browser = lib.mkOption {
        type = lib.types.str;
        default = "firefox";
        description = "Default web browser";
      };

      screenshot = lib.mkOption {
        type = lib.types.str;
        default = "grim";
        description = "Screenshot tool";
      };
    };

    # Theme and styling
    theme = {
      enable = lib.mkEnableOption "custom theming" // {
        default = true;
      };

      colorScheme = lib.mkOption {
        type = lib.types.enum [
          "dark"
          "light"
          "auto"
        ];
        default = "dark";
        description = "Color scheme preference";
      };

      wallpaper = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to wallpaper image";
      };

      cursor = {
        theme = lib.mkOption {
          type = lib.types.str;
          default = "Adwaita";
          description = "Cursor theme";
        };

        size = lib.mkOption {
          type = lib.types.int;
          default = 24;
          description = "Cursor size";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Niri
    programs.niri.enable = true;

    # NOTE: config.kdl is no longer written here. The config lives in
    # home/profiles/niri.nix as structured programs.niri.settings, provided by
    # niri-flake, so it is per-user and typed rather than a KDL string.

    # Essential packages for Niri and Waybar
    environment.systemPackages =
      with pkgs;
      lib.optionals cfg.waybar.enable [
        waybar
      ]
      ++ lib.optionals cfg.dunst.enable [
        dunst
      ]
      ++ [
        # Core Wayland utilities
        wl-clipboard # Clipboard manager
        wlr-randr # Display configuration

        # Application launcher (fuzzel works great with niri)
        fuzzel # Fast application launcher

        # Terminal emulators
        alacritty # Default terminal

        # File manager
        thunar # File manager

        # Screenshot and screen recording
        grim # Screenshot tool
        slurp # Screen area selection
        swappy # Screenshot annotation
        wf-recorder # Screen recorder

        # Wallpaper
        swaybg # Wallpaper setter

        # System utilities
        brightnessctl # Brightness control
        pamixer # Audio control
        pavucontrol # Audio mixer GUI

        # Screen locker
        swaylock # Screen locker

        # Theme and appearance
        gtk3 # GTK3 for theme support
        adwaita-icon-theme
        gnome-themes-extra

        # Fonts
        jetbrains-mono
        font-awesome

        # Media
        imv # Image viewer
        mpv # Video player

        # Archive support for file manager
        file-roller # Archive manager

        # Network management
        networkmanagerapplet

        # System information
        fastfetch # System info

        # PDF viewer
        zathura # Minimal PDF viewer
      ];

    # Waybar configuration file
    environment.etc."xdg/waybar/config".text = lib.mkIf cfg.waybar.enable (
      builtins.toJSON {
        mainBar = {
          layer = "top";
          inherit (cfg.waybar) position;
          height = 35;
          spacing = 4;

          modules-left = [
            "niri/workspaces"
            "niri/window"
          ];
          modules-center = [ "clock" ];
          modules-right = [
            "pulseaudio"
            "network"
            "battery"
            "tray"
          ];

          # Niri-specific modules
          "niri/workspaces" = lib.mkIf cfg.waybar.modules.workspaces {
            current-only = false;
            all-outputs = true;
          };

          "niri/window" = lib.mkIf cfg.waybar.modules.window {
            format = "{}";
            max-length = 50;
            rewrite = {
              "(.*) — Mozilla Firefox" = " $1";
              "(.*) - Visual Studio Code" = "󰨞 $1";
            };
          };

          clock = lib.mkIf cfg.waybar.modules.clock {
            timezone = "UTC";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%Y-%m-%d}";
          };

          battery = lib.mkIf cfg.waybar.modules.battery {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-plugged = "{capacity}% ";
            format-alt = "{time} {icon}";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
          };

          network = lib.mkIf cfg.waybar.modules.network {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} ";
            tooltip-format = "{ifname} via {gwaddr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };

          pulseaudio = lib.mkIf cfg.waybar.modules.pulseaudio {
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = "{volume}% ";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "pavucontrol";
          };

          tray = lib.mkIf cfg.waybar.modules.tray {
            spacing = 10;
          };
        };
      }
    );

    # Waybar style configuration
    environment.etc."xdg/waybar/style.css".text = lib.mkIf cfg.waybar.enable ''
      * {
          border: none;
          border-radius: 0;
          font-family: "JetBrains Mono", "Font Awesome 6 Free";
          font-size: 13px;
          min-height: 0;
      }

      window#waybar {
          background-color: rgba(30, 30, 46, 0.8);
          color: #cdd6f4;
          transition-property: background-color;
          transition-duration: .5s;
          border-bottom: 2px solid #cba6f7;
      }

      window#waybar.hidden {
          opacity: 0.2;
      }

      #workspaces {
          margin: 0 4px;
      }

      #workspaces button {
          padding: 0 8px;
          background-color: transparent;
          color: #cdd6f4;
          border: 2px solid transparent;
          border-radius: 4px;
          margin: 0 2px;
      }

      #workspaces button:hover {
          background: rgba(203, 166, 247, 0.2);
          border-color: #cba6f7;
      }

      #workspaces button.active {
          background-color: #cba6f7;
          color: #1e1e2e;
          border-color: #cba6f7;
      }

      #workspaces button.urgent {
          background-color: #f38ba8;
          color: #1e1e2e;
          border-color: #f38ba8;
      }

      #window {
          margin: 0 4px;
          padding: 0 8px;
          color: #a6e3a1;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #mpd {
          padding: 0 10px;
          color: #cdd6f4;
          border-radius: 4px;
          margin: 2px 2px;
      }

      #battery.charging, #battery.plugged {
          color: #a6e3a1;
      }

      @keyframes blink {
          to {
              background-color: #f38ba8;
              color: #1e1e2e;
          }
      }

      #battery.critical:not(.charging) {
          background-color: #f38ba8;
          color: #1e1e2e;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      #pulseaudio:hover,
      #network:hover,
      #battery:hover,
      #clock:hover {
          background-color: rgba(203, 166, 247, 0.1);
      }

      #pulseaudio.muted {
          color: #6c7086;
      }

      #network.disconnected {
          color: #f38ba8;
      }
    '';

    # Dunst notification daemon configuration
    environment.etc."xdg/dunst/dunstrc".text = lib.mkIf cfg.dunst.enable ''
      [global]
      monitor = 0
      follow = mouse
      geometry = "300x5-30+20"
      indicate_hidden = yes
      shrink = no
      transparency = 20
      notification_height = 0
      separator_height = 2
      padding = 8
      horizontal_padding = 8
      frame_width = 3
      frame_color = "#cba6f7"
      separator_color = frame
      sort = yes
      idle_threshold = 120
      font = JetBrains Mono 10
      line_height = 0
      markup = full
      format = "<b>%s</b>\n%b"
      alignment = left
      vertical_alignment = center
      show_age_threshold = 60
      word_wrap = yes
      ellipsize = middle
      ignore_newline = no
      stack_duplicates = true
      hide_duplicate_count = false
      show_indicators = yes
      icon_position = left
      min_icon_size = 0
      max_icon_size = 32
      sticky_history = yes
      history_length = 20
      browser = ${cfg.applications.browser}
      always_run_script = true
      title = Dunst
      class = Dunst
      startup_notification = false
      verbosity = mesg
      corner_radius = 8
      ignore_dbusclose = false
      force_xinerama = false
      mouse_left_click = close_current
      mouse_middle_click = do_action, close_current
      mouse_right_click = close_all

      [experimental]
      per_monitor_dpi = false

      [urgency_low]
      background = "#1e1e2e"
      foreground = "#a6adc8"
      timeout = ${toString cfg.dunst.settings.urgency_low.timeout}
      frame_color = "#313244"

      [urgency_normal]
      background = "#1e1e2e"
      foreground = "#cdd6f4"
      timeout = ${toString cfg.dunst.settings.urgency_normal.timeout}
      frame_color = "#cba6f7"

      [urgency_critical]
      background = "#1e1e2e"
      foreground = "#f38ba8"
      frame_color = "#f38ba8"
      timeout = ${toString cfg.dunst.settings.urgency_critical.timeout}
    '';

    # (systemPackages merged above)

    # XDG portal for better app integration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome # For compatibility
        xdg-desktop-portal-gtk
      ];

      config = {
        common = {
          default = [ "gtk" ];
        };
      };
    };

    # Security and authentication
    security = {
      polkit.enable = true;
      pam.services.swaylock = { };
    };

    programs = {
      # Thunar file manager
      thunar = {
        enable = true;
        plugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
        ];
      };

      # dconf for GTK application settings
      dconf.enable = true;
    };

    # Services for desktop functionality
    services = {
      # Desktop services
      gvfs.enable = true; # Virtual filesystems
      udisks2.enable = true; # Disk management
      upower.enable = true; # Power management
      accounts-daemon.enable = true; # Account management
      gnome.gnome-keyring.enable = true; # Keyring for secrets

      # Audio is owned by modules/desktop/audio.nix. This module used to
      # repeat the whole pipewire block, and its `jack.enable = false` collided
      # with audio.nix's `true`, so any host enabling both failed to evaluate.

      # Display manager (minimal)
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri";
            user = "greeter";
          };
        };
      };
    };

    # Fonts configuration
    fonts = {
      packages = with pkgs; [
        jetbrains-mono
        font-awesome
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];

      fontconfig = {
        enable = true;
        defaultFonts = {
          monospace = [ "JetBrains Mono" ];
        };
      };
    };

    # Environment variables
    environment.sessionVariables = {
      # Wayland variables
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";

      # Qt/GTK theming
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

      # Cursor theme
      XCURSOR_THEME = cfg.theme.cursor.theme;
      XCURSOR_SIZE = toString cfg.theme.cursor.size;

      # Firefox Wayland
      MOZ_ENABLE_WAYLAND = "1";

      # Java applications on Wayland
      _JAVA_AWT_WM_NONREPARENTING = "1";

      # SDL Wayland
      SDL_VIDEODRIVER = "wayland";

      # Clutter Wayland
      CLUTTER_BACKEND = "wayland";
    };

    # Assertions to prevent conflicts
    assertions = [
      {
        assertion = !(cfg.enable && config.modules.desktop.gnome.enable);
        message = "Cannot enable both Niri and GNOME desktop environments";
      }
      {
        assertion = !(cfg.enable && config.modules.desktop.hyprland.enable);
        message = "Cannot enable both Niri and Hyprland desktop environments";
      }
    ];
  };
}
