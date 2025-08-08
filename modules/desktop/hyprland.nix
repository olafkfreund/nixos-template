{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.hyprland;
in
{
  options.modules.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";

    # Hyprland configuration
    settings = {
      # Monitor configuration
      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "DP-1,1920x1080@60,0x0,1" ];
        description = "Monitor configuration for Hyprland";
      };

      # Input configuration
      input = {
        kb_layout = lib.mkOption {
          type = lib.types.str;
          default = "us";
          description = "Keyboard layout";
        };

        follow_mouse = lib.mkOption {
          type = lib.types.int;
          default = 1;
          description = "Follow mouse setting (0-2)";
        };

        touchpad = {
          natural_scroll = lib.mkEnableOption "natural scrolling for touchpad" // { default = true; };
          disable_while_typing = lib.mkEnableOption "disable touchpad while typing" // { default = true; };
        };
      };

      # Appearance
      appearance = {
        gaps_in = lib.mkOption {
          type = lib.types.int;
          default = 8;
          description = "Inner gaps size";
        };

        gaps_out = lib.mkOption {
          type = lib.types.int;
          default = 16;
          description = "Outer gaps size";
        };

        border_size = lib.mkOption {
          type = lib.types.int;
          default = 2;
          description = "Border size";
        };

        rounding = lib.mkOption {
          type = lib.types.int;
          default = 8;
          description = "Window rounding";
        };
      };

      # Animations
      animations = {
        enable = lib.mkEnableOption "animations" // { default = true; };
        speed = lib.mkOption {
          type = lib.types.float;
          default = 1.0;
          description = "Animation speed multiplier";
        };
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
        type = lib.types.enum [ "default" "minimal" "colorful" ];
        default = "default";
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
        default = "wofi";
        description = "Application launcher";
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
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # Hyprland configuration
    environment.etc."hypr/hyprland.conf".text = ''
      # Monitor configuration
      ${lib.concatMapStringsSep "\n" (monitor: "monitor=${monitor}") cfg.settings.monitors}
      
      # Input configuration
      input {
          kb_layout = ${cfg.settings.input.kb_layout}
          follow_mouse = ${toString cfg.settings.input.follow_mouse}
          
          touchpad {
              natural_scroll = ${if cfg.settings.input.touchpad.natural_scroll then "yes" else "no"}
              disable_while_typing = ${if cfg.settings.input.touchpad.disable_while_typing then "yes" else "no"}
          }
      }
      
      # General configuration
      general {
          gaps_in = ${toString cfg.settings.appearance.gaps_in}
          gaps_out = ${toString cfg.settings.appearance.gaps_out}
          border_size = ${toString cfg.settings.appearance.border_size}
          
          # Border colors (Catppuccin-inspired)
          col.active_border = rgba(cba6f7ee) rgba(89b4faee) 45deg
          col.inactive_border = rgba(585b70aa)
          
          resize_on_border = false
          allow_tearing = false
          layout = dwindle
      }
      
      # Decoration
      decoration {
          rounding = ${toString cfg.settings.appearance.rounding}
          
          # Opacity
          active_opacity = 1.0
          inactive_opacity = 1.0
          
          # Shadow
          drop_shadow = true
          shadow_range = 4
          shadow_render_power = 3
          col.shadow = rgba(1a1a1aee)
          
          # Blur
          blur {
              enabled = true
              size = 3
              passes = 1
              
              vibrancy = 0.1696
          }
      }
      
      # Animations
      animations {
          enabled = ${if cfg.settings.animations.enable then "yes" else "no"}
          
          bezier = myBezier, 0.05, 0.9, 0.1, 1.05
          
          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = borderangle, 1, 8, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
      }
      
      # Layout configuration
      dwindle {
          pseudotile = yes
          preserve_split = yes
      }
      
      master {
          new_is_master = true
      }
      
      # Gestures
      gestures {
          workspace_swipe = false
      }
      
      # Misc settings
      misc { 
          force_default_wallpaper = 0
          disable_hyprland_logo = false
      }
      
      # Key bindings
      $mainMod = SUPER
      
      # Application bindings
      bind = $mainMod, Q, exec, ${cfg.applications.terminal}
      bind = $mainMod, C, killactive, 
      bind = $mainMod, M, exit, 
      bind = $mainMod, E, exec, ${cfg.applications.fileManager}
      bind = $mainMod, V, togglefloating, 
      bind = $mainMod, R, exec, ${cfg.applications.launcher}
      bind = $mainMod, P, pseudo,
      bind = $mainMod, J, togglesplit,
      bind = $mainMod, B, exec, ${cfg.applications.browser}
      
      # Screenshot bindings
      bind = , Print, exec, ${cfg.applications.screenshot} -g "$(slurp)" - | wl-copy
      bind = $mainMod, Print, exec, ${cfg.applications.screenshot} - | wl-copy
      
      # Move focus with mainMod + arrow keys
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d
      
      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10
      
      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10
      
      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1
      
      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow
      
      # Volume and brightness controls
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bind = , XF86MonBrightnessUp, exec, brightnessctl set 10%+
      bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-
      
      # Autostart applications
      exec-once = waybar
      exec-once = dunst
      ${lib.optionalString (cfg.theme.wallpaper != "") "exec-once = swaybg -i ${cfg.theme.wallpaper}"}
    '';

    # Essential packages for Hyprland and Waybar
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
      wlogout # Logout menu

      # Application launcher and menus
      wofi # Application launcher
      rofi-wayland # Alternative launcher

      # Terminal
      alacritty # Default terminal
      kitty # Alternative terminal

      # File manager
      thunar # File manager

      # Screenshot and screen recording
      grim # Screenshot tool
      slurp # Screen area selection
      swappy # Screenshot annotation
      wf-recorder # Screen recorder

      # Wallpaper
      swaybg # Wallpaper setter
      hyprpaper # Hyprland wallpaper daemon

      # System utilities
      brightnessctl # Brightness control
      pamixer # Audio control
      pavucontrol # Audio mixer GUI

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

      # Clipboard manager
      clipman # Clipboard history

      # Color picker
      hyprpicker # Color picker for Hyprland

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

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "battery"
          "tray"
        ];

        # Module configurations
        "hyprland/workspaces" = lib.mkIf cfg.waybar.modules.workspaces {
          disable-scroll = true;
          all-outputs = true;
        };

        "hyprland/window" = lib.mkIf cfg.waybar.modules.window {
          format = "{title}";
          max-length = 50;
        };

        clock = lib.mkIf cfg.waybar.modules.clock {
          timezone = "UTC";
          tooltip-format = "<big>{:%Y %B}</big>\\n<tt><small>{calendar}</small></tt>";
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
          background-color: transparent;
          color: #ffffff;
          transition-property: background-color;
          transition-duration: .5s;
      }
      
      window#waybar.hidden {
          opacity: 0.2;
      }
      
      #workspaces {
          margin: 0 4px;
      }
      
      #workspaces button {
          padding: 0 5px;
          background-color: transparent;
          color: #ffffff;
          border-bottom: 3px solid transparent;
      }
      
      #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
      }
      
      #workspaces button.active {
          background-color: #64727D;
          border-bottom: 3px solid #ffffff;
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
          color: #ffffff;
      }
      
      #window {
          margin: 0 4px;
      }
      
      #battery.charging, #battery.plugged {
          color: #26A65B;
      }
      
      @keyframes blink {
          to {
              background-color: #ffffff;
              color: #000000;
          }
      }
      
      #battery.critical:not(.charging) {
          background-color: #f53c3c;
          color: #ffffff;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
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
      frame_color = "#aaaaaa"
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
      background = "#282828"
      foreground = "#928374"
      timeout = ${toString cfg.dunst.settings.urgency_low.timeout}
      frame_color = "#32302f"
      
      [urgency_normal]
      background = "#458588"
      foreground = "#ebdbb2"
      timeout = ${toString cfg.dunst.settings.urgency_normal.timeout}
      frame_color = "#689d6a"
      
      [urgency_critical]
      background = "#cc241d"
      foreground = "#ebdbb2"
      frame_color = "#fb4934"
      timeout = ${toString cfg.dunst.settings.urgency_critical.timeout}
    '';

    # (systemPackages merged above)

    # XDG portal for better app integration
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];

      config = {
        common = {
          default = [ "hyprland" "gtk" ];
        };
        hyprland = {
          default = [ "hyprland" "gtk" ];
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
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
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
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
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
        message = "Cannot enable both Hyprland and GNOME desktop environments";
      }
      {
        assertion = !(cfg.enable && config.modules.desktop.kde.enable);
        message = "Cannot enable both Hyprland and KDE desktop environments";
      }
    ];
  };
}
