{ config, lib, pkgs, ... }:

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
          natural-scroll = lib.mkEnableOption "natural scrolling" // { default = false; };
          accel-speed = lib.mkOption {
            type = lib.types.float;
            default = 0.0;
            description = "Mouse acceleration speed";
          };
          accel-profile = lib.mkOption {
            type = lib.types.enum [ "flat" "adaptive" ];
            default = "adaptive";
            description = "Mouse acceleration profile";
          };
        };

        touchpad = {
          tap = lib.mkEnableOption "tap to click" // { default = true; };
          dwt = lib.mkEnableOption "disable while typing" // { default = true; };
          natural-scroll = lib.mkEnableOption "natural scrolling for touchpad" // { default = true; };
          click-method = lib.mkOption {
            type = lib.types.enum [ "button-areas" "clickfinger" ];
            default = "clickfinger";
            description = "Touchpad click method";
          };
        };
      };

      # Output configuration
      outputs = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Output name (e.g., DP-1, HDMI-A-1)";
            };
            mode = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
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
              });
              default = null;
              description = "Output mode configuration";
            };
            scale = lib.mkOption {
              type = lib.types.float;
              default = 1.0;
              description = "Output scale factor";
            };
            transform = lib.mkOption {
              type = lib.types.enum [ "normal" "90" "180" "270" "flipped" "flipped-90" "flipped-180" "flipped-270" ];
              default = "normal";
              description = "Output transformation";
            };
            position = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
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
              });
              default = null;
              description = "Output position";
            };
          };
        });
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
          type = lib.types.enum [ "never" "always" "on-overflow" ];
          default = "on-overflow";
          description = "When to center the focused column";
        };

        preset-column-widths = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              proportion = lib.mkOption {
                type = lib.types.float;
                description = "Width as proportion of screen width";
              };
            };
          });
          default = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
            { proportion = 0.66667; }
          ];
          description = "Preset column width proportions";
        };

        default-column-width = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              proportion = lib.mkOption {
                type = lib.types.float;
                description = "Default width as proportion of screen width";
              };
            };
          });
          default = { proportion = 0.5; };
          description = "Default column width";
        };
      };

      # Window rules
      window-rules = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            matches = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
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
              });
              description = "Window matching criteria";
            };

            default-column-width = lib.mkOption {
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  proportion = lib.mkOption {
                    type = lib.types.float;
                    description = "Width proportion";
                  };
                };
              });
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
        });
        default = [ ];
        description = "Window rules for specific applications";
      };

      # Appearance
      prefer-no-csd = lib.mkEnableOption "prefer server-side decorations" // { default = false; };

      hotkey-overlay = {
        skip-at-startup = lib.mkEnableOption "skip hotkey overlay at startup" // { default = false; };
      };

      screenshot-path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path for screenshots (null for clipboard)";
      };
    };

    # Waybar configuration
    waybar = {
      enable = lib.mkEnableOption "Waybar status bar" // { default = true; };
      position = lib.mkOption {
        type = lib.types.enum [ "top" "bottom" ];
        default = "top";
        description = "Waybar position";
      };

      modules = {
        workspaces = lib.mkEnableOption "workspace indicator" // { default = true; };
        window = lib.mkEnableOption "window title" // { default = true; };
        clock = lib.mkEnableOption "clock widget" // { default = true; };
        battery = lib.mkEnableOption "battery widget" // { default = true; };
        network = lib.mkEnableOption "network widget" // { default = true; };
        pulseaudio = lib.mkEnableOption "audio widget" // { default = true; };
        tray = lib.mkEnableOption "system tray" // { default = true; };
      };

      theme = lib.mkOption {
        type = lib.types.enum [ "default" "minimal" "niri" ];
        default = "niri";
        description = "Waybar theme style";
      };
    };

    # Dunst notification daemon
    dunst = {
      enable = lib.mkEnableOption "Dunst notification daemon" // { default = true; };

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
      enable = lib.mkEnableOption "custom theming" // { default = true; };

      colorScheme = lib.mkOption {
        type = lib.types.enum [ "dark" "light" "auto" ];
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

    # Niri configuration file
    environment.etc."niri/config.kdl".text = ''
      // Niri configuration in KDL format
      
      input {
          keyboard {
              xkb {
                  layout "${cfg.settings.input.keyboard.xkb.layout}"
                  ${lib.optionalString (cfg.settings.input.keyboard.xkb.variant != "") ''variant "${cfg.settings.input.keyboard.xkb.variant}"''}
                  ${lib.optionalString (cfg.settings.input.keyboard.xkb.options != null) ''options "${cfg.settings.input.keyboard.xkb.options}"''}
              }
              
              repeat-delay ${toString cfg.settings.input.keyboard.repeat-delay}
              repeat-rate ${toString cfg.settings.input.keyboard.repeat-rate}
          }
          
          mouse {
              natural-scroll ${if cfg.settings.input.mouse.natural-scroll then "true" else "false"}
              accel-speed ${toString cfg.settings.input.mouse.accel-speed}
              accel-profile "${cfg.settings.input.mouse.accel-profile}"
          }
          
          touchpad {
              tap ${if cfg.settings.input.touchpad.tap then "true" else "false"}
              dwt ${if cfg.settings.input.touchpad.dwt then "true" else "false"}
              natural-scroll ${if cfg.settings.input.touchpad.natural-scroll then "true" else "false"}
              click-method "${cfg.settings.input.touchpad.click-method}"
          }
      }
      
      ${lib.concatMapStringsSep "\n" (output: ''
        output "${output.name}" {
            ${lib.optionalString (output.mode != null) ''
              mode ${toString output.mode.width}x${toString output.mode.height}@${toString output.mode.refresh}
            ''}
            scale ${toString output.scale}
            transform ${output.transform}
            ${lib.optionalString (output.position != null) ''
              position ${toString output.position.x} ${toString output.position.y}
            ''}
        }
      '') cfg.settings.outputs}
      
      layout {
          gaps ${toString cfg.settings.layout.gaps}
          center-focused-column "${cfg.settings.layout.center-focused-column}"
          
          preset-column-widths {
              ${lib.concatMapStringsSep "\n          " (width: ''proportion ${toString width.proportion}'') cfg.settings.layout.preset-column-widths}
          }
          
          ${lib.optionalString (cfg.settings.layout.default-column-width != null) ''
            default-column-width { proportion ${toString cfg.settings.layout.default-column-width.proportion} }
          ''}
      }
      
      ${lib.concatMapStringsSep "\n" (rule: ''
        window-rule {
            ${lib.concatMapStringsSep "\n        " (match: ''
              ${lib.optionalString (match.app-id != null) ''match app-id="${match.app-id}"''}
              ${lib.optionalString (match.title != null) ''match title="${match.title}"''}
            '') rule.matches}
            
            ${lib.optionalString (rule.default-column-width != null) ''
              default-column-width { proportion ${toString rule.default-column-width.proportion} }
            ''}
            ${lib.optionalString (rule.open-on-output != null) ''open-on-output "${rule.open-on-output}"''}
            ${lib.optionalString (rule.open-maximized != null) ''open-maximized ${if rule.open-maximized then "true" else "false"}''}
            ${lib.optionalString (rule.open-fullscreen != null) ''open-fullscreen ${if rule.open-fullscreen then "true" else "false"}''}
        }
      '') cfg.settings.window-rules}
      
      prefer-no-csd ${if cfg.settings.prefer-no-csd then "true" else "false"}
      
      hotkey-overlay {
          skip-at-startup ${if cfg.settings.hotkey-overlay.skip-at-startup then "true" else "false"}
      }
      
      ${lib.optionalString (cfg.settings.screenshot-path != null) ''
        screenshot-path "${cfg.settings.screenshot-path}"
      ''}
      
      spawn-at-startup "waybar"
      spawn-at-startup "dunst"
      ${lib.optionalString (cfg.theme.wallpaper != "") ''spawn-at-startup "swaybg" "-i" "${cfg.theme.wallpaper}"''}
      
      // Niri key bindings
      binds {
          Mod+Shift+Slash { show-hotkey-overlay; }
          
          Mod+T { spawn "${cfg.applications.terminal}"; }
          Mod+D { spawn "${cfg.applications.launcher}"; }
          Mod+Q { close-window; }
          
          XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
          XF86AudioLowerVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
          XF86AudioMute { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
          
          XF86MonBrightnessUp { spawn "brightnessctl" "set" "10%+"; }
          XF86MonBrightnessDown { spawn "brightnessctl" "set" "10%-"; }
          
          Print { spawn "${cfg.applications.screenshot}" "-g" "$(slurp)" "-" "|" "wl-copy"; }
          Mod+Print { spawn "${cfg.applications.screenshot}" "-" "|" "wl-copy"; }
          
          Mod+Left { focus-column-left; }
          Mod+Right { focus-column-right; }
          Mod+Up { focus-window-up; }
          Mod+Down { focus-window-down; }
          Mod+H { focus-column-left; }
          Mod+L { focus-column-right; }
          Mod+K { focus-window-up; }
          Mod+J { focus-window-down; }
          
          Mod+Ctrl+Left { move-column-left; }
          Mod+Ctrl+Right { move-column-right; }
          Mod+Ctrl+Up { move-window-up; }
          Mod+Ctrl+Down { move-window-down; }
          Mod+Ctrl+H { move-column-left; }
          Mod+Ctrl+L { move-column-right; }
          Mod+Ctrl+K { move-window-up; }
          Mod+Ctrl+J { move-window-down; }
          
          Mod+Home { focus-column-first; }
          Mod+End { focus-column-last; }
          Mod+Ctrl+Home { move-column-to-first; }
          Mod+Ctrl+End { move-column-to-last; }
          
          Mod+Shift+Left { focus-monitor-left; }
          Mod+Shift+Right { focus-monitor-right; }
          Mod+Shift+Up { focus-monitor-up; }
          Mod+Shift+Down { focus-monitor-down; }
          Mod+Shift+H { focus-monitor-left; }
          Mod+Shift+L { focus-monitor-right; }
          Mod+Shift+K { focus-monitor-up; }
          Mod+Shift+J { focus-monitor-down; }
          
          Mod+Shift+Ctrl+Left { move-column-to-monitor-left; }
          Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
          Mod+Shift+Ctrl+Up { move-column-to-monitor-up; }
          Mod+Shift+Ctrl+Down { move-column-to-monitor-down; }
          Mod+Shift+Ctrl+H { move-column-to-monitor-left; }
          Mod+Shift+Ctrl+L { move-column-to-monitor-right; }
          Mod+Shift+Ctrl+K { move-column-to-monitor-up; }
          Mod+Shift+Ctrl+J { move-column-to-monitor-down; }
          
          Mod+Page_Down { focus-workspace-down; }
          Mod+Page_Up { focus-workspace-up; }
          Mod+U { focus-workspace-down; }
          Mod+I { focus-workspace-up; }
          
          Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
          Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
          Mod+Ctrl+U { move-column-to-workspace-down; }
          Mod+Ctrl+I { move-column-to-workspace-up; }
          
          Mod+Shift+Page_Down { move-workspace-down; }
          Mod+Shift+Page_Up { move-workspace-up; }
          Mod+Shift+U { move-workspace-down; }
          Mod+Shift+I { move-workspace-up; }
          
          Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
          Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
          Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
          Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }
          
          Mod+WheelScrollRight { focus-column-right; }
          Mod+WheelScrollLeft { focus-column-left; }
          Mod+Ctrl+WheelScrollRight { move-column-right; }
          Mod+Ctrl+WheelScrollLeft { move-column-left; }
          
          Mod+Shift+WheelScrollDown { focus-column-right; }
          Mod+Shift+WheelScrollUp { focus-column-left; }
          Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
          Mod+Ctrl+Shift+WheelScrollUp { move-column-left; }
          
          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }
          Mod+5 { focus-workspace 5; }
          Mod+6 { focus-workspace 6; }
          Mod+7 { focus-workspace 7; }
          Mod+8 { focus-workspace 8; }
          Mod+9 { focus-workspace 9; }
          
          Mod+Ctrl+1 { move-column-to-workspace 1; }
          Mod+Ctrl+2 { move-column-to-workspace 2; }
          Mod+Ctrl+3 { move-column-to-workspace 3; }
          Mod+Ctrl+4 { move-column-to-workspace 4; }
          Mod+Ctrl+5 { move-column-to-workspace 5; }
          Mod+Ctrl+6 { move-column-to-workspace 6; }
          Mod+Ctrl+7 { move-column-to-workspace 7; }
          Mod+Ctrl+8 { move-column-to-workspace 8; }
          Mod+Ctrl+9 { move-column-to-workspace 9; }
          
          Mod+Comma { consume-window-into-column; }
          Mod+Period { expel-window-from-column; }
          
          Mod+R { switch-preset-column-width; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }
          Mod+C { center-column; }
          
          Mod+Minus { set-column-width "-10%"; }
          Mod+Equal { set-column-width "+10%"; }
          
          Mod+Shift+Minus { set-window-height "-10%"; }
          Mod+Shift+Equal { set-window-height "+10%"; }
          
          Print { screenshot; }
          Mod+Ctrl+L { spawn "swaylock"; }
          
          Mod+Shift+E { quit; }
          Mod+Shift+P { power-off-monitors; }
          
          Mod+Shift+Ctrl+T { toggle-debug-tint; }
      }
    '';

    # Essential packages for Niri and Waybar
    environment.systemPackages = with pkgs; [
      # Waybar (if enabled)
    ] ++ lib.optionals cfg.waybar.enable [
      waybar
    ] ++ lib.optionals cfg.dunst.enable [
      dunst
    ] ++ [
      # Core Wayland utilities
      wl-clipboard # Clipboard manager
      wlr-randr # Display configuration

      # Application launcher (fuzzel works great with niri)
      fuzzel # Fast application launcher
      wofi # Alternative launcher

      # Terminal emulators
      alacritty # Default terminal
      foot # Lightweight Wayland terminal

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
    environment.etc."xdg/waybar/config".text = lib.mkIf cfg.waybar.enable (builtins.toJSON {
      mainBar = {
        layer = "top";
        position = cfg.waybar.position;
        height = 35;
        spacing = 4;

        modules-left = [ "niri/workspaces" "niri/window" ];
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
          format-icons = [ "" "" "" "" "" ];
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
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        tray = lib.mkIf cfg.waybar.modules.tray {
          spacing = 10;
        };
      };
    });

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
        plugins = with pkgs.xfce; [
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

      # Audio
      pipewire = {
        enable = true;
        audio.enable = true;
        pulse.enable = true;
        jack.enable = false;

        # Low latency configuration
        extraConfig.pipewire = {
          "92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 1024;
            };
          };
        };
      };

      # Display manager (minimal)
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd niri";
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
        noto-fonts-cjk
        noto-fonts-emoji
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
        assertion = !(cfg.enable && config.modules.desktop.kde.enable);
        message = "Cannot enable both Niri and KDE desktop environments";
      }
      {
        assertion = !(cfg.enable && config.modules.desktop.hyprland.enable);
        message = "Cannot enable both Niri and Hyprland desktop environments";
      }
    ];
  };
}
