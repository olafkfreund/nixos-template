{ config, pkgs, ... }:

{
  # Niri-specific Home Manager configuration

  # Wayland/Niri applications
  home.packages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    wlr-randr

    # Application launcher (fuzzel is great for niri)
    fuzzel

    # Terminal emulators
    alacritty

    # File managers
    thunar

    # Screenshot and screen recording
    grim
    slurp
    swappy
    wf-recorder

    # Media and viewers
    # NOTE: imv, mpv, zathura also in hyprland.nix - avoid duplicates
    # Users should import only one Wayland WM profile to prevent collisions

    # System utilities
    brightnessctl
    pamixer
    pavucontrol

    # Theme and appearance
    adwaita-icon-theme
    gnome-themes-extra

    # Network management
    networkmanagerapplet

    # Archive support
    file-roller

    # System info
    fastfetch

    # Screen locker
    swaylock
  ];

  # Alacritty terminal configuration (optimized for niri)
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.95;
        padding = {
          x = 12;
          y = 12;
        };
        dynamic_title = true;
      };

      font = {
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
        bold = {
          family = "JetBrains Mono";
          style = "Bold";
        };
        italic = {
          family = "JetBrains Mono";
          style = "Italic";
        };
        size = 12.0;
      };

      # Catppuccin Mocha theme (works well with niri)
      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
          dim_foreground = "#7f849c";
          bright_foreground = "#cdd6f4";
        };

        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
        };

        vi_mode_cursor = {
          text = "#1e1e2e";
          cursor = "#b4befe";
        };

        search = {
          matches = {
            foreground = "#1e1e2e";
            background = "#a6adc8";
          };
          focused_match = {
            foreground = "#1e1e2e";
            background = "#a6e3a1";
          };
        };

        footer_bar = {
          foreground = "#1e1e2e";
          background = "#a6adc8";
        };

        hints = {
          start = {
            foreground = "#1e1e2e";
            background = "#f9e2af";
          };
          end = {
            foreground = "#1e1e2e";
            background = "#a6adc8";
          };
        };

        selection = {
          text = "#1e1e2e";
          background = "#f5e0dc";
        };

        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };

        bright = {
          black = "#585b70";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#a6adc8";
        };

        dim = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#f5c2e7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };

        indexed_colors = [
          {
            index = 16;
            color = "#fab387";
          }
          {
            index = 17;
            color = "#f5e0dc";
          }
        ];
      };

      bell = {
        animation = "EaseOutExpo";
        duration = 0;
      };
    };
  };

  # Fuzzel launcher configuration (excellent for niri)
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.alacritty}/bin/alacritty";
        layer = "overlay";
        font = "JetBrains Mono:size=12";
        dpi-aware = "yes";
        icon-theme = "Adwaita";
        fields = "filename,name,generic";
        password-character = "*";
        filter-desktop = false;
        show-actions = true;
        tabs = "2";
        width = 50;
        horizontal-pad = 20;
        vertical-pad = 8;
        inner-pad = 8;
      };

      colors = {
        background = "1e1e2edd";
        text = "cdd6f4ff";
        match = "a6e3a1ff";
        selection = "585b70ff";
        selection-text = "cdd6f4ff";
        selection-match = "a6e3a1ff";
        border = "cba6f7ff";
      };

      border = {
        width = 2;
        radius = 8;
      };
    };
  };

  # Foot terminal (alternative lightweight terminal)

  # Waybar configuration (handled by system module but can be customized)
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  # Swaylock screen locker configuration
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      line-color = "313244";
      ring-color = "cba6f7";
      inside-color = "1e1e2e";
      key-hl-color = "a6e3a1";
      text-color = "cdd6f4";
      show-failed-attempts = true;
      fade-in = 0.2;
      effect-blur = "7x5";
      effect-vignette = "0.5:0.5";
      grace = 2;
      grace-no-mouse = true;
      grace-no-touch = true;
    };
  };

  # GTK theming for applications
  gtk = {
    enable = true;

    theme = {
      package = pkgs.adwaita-qt;
      name = "Adwaita-dark";
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    cursorTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    };

    font = {
      name = "Inter";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Qt theming
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  # Niri-specific session variables
  home.sessionVariables = {
    # Wayland
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";

    # Qt
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # Firefox Wayland
    MOZ_ENABLE_WAYLAND = "1";

    # Cursor theme
    XCURSOR_THEME = "Adwaita";
    XCURSOR_SIZE = "24";

    # Java applications
    _JAVA_AWT_WM_NONREPARENTING = "1";

    # SDL
    SDL_VIDEODRIVER = "wayland";

    # Niri-specific
    NIRI_CONFIG = "${config.xdg.configHome}/niri/config.kdl";
  };

  # User services for niri
  systemd.user.services = {
    # Waybar for niri
    waybar-niri = {
      Unit = {
        Description = "Waybar for Niri";
        Documentation = "https://github.com/Alexays/Waybar/wiki";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
        KillMode = "mixed";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Background wallpaper service
    swaybg = {
      Unit = {
        Description = "Wallpaper daemon for Wayland";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i %h/.config/wallpaper.jpg";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

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

    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "application/pdf" = "zathura.desktop";
        "image/*" = "imv.desktop";
        "video/*" = "mpv.desktop";
        "audio/*" = "mpv.desktop";
        "inode/directory" = "thunar.desktop";
      };
    };

  };

  # Shell configuration optimized for niri
  programs.bash = {
    shellAliases = {
      # Niri-specific aliases
      "niri-msg" = "niri msg";
      "niri-reload" = "niri msg action reload-config";
      "niri-debug" = "niri msg action toggle-debug-tint";

      # Screenshot aliases
      "screenshot" = "grim ~/Pictures/Screenshots/$(date +'%Y%m%d_%H%M%S').png";
      "screenshot-area" = "grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +'%Y%m%d_%H%M%S').png";
      "screenshot-clipboard" = "grim - | wl-copy";
      "screenshot-area-clipboard" = "grim -g \"$(slurp)\" - | wl-copy";
    };

    sessionVariables = {
      # Niri-specific environment
      NIRI_SOCKET = "$XDG_RUNTIME_DIR/niri/niri.sock";
    };
  };

  # Create screenshots directory
  home.file."Pictures/Screenshots/.keep".text = "";

  # Niri keybindings reference (as a desktop file)
  xdg.desktopEntries.niri-keybindings = {
    name = "Niri Keybindings";
    comment = "Reference for Niri window manager keybindings";
    exec = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.less}/bin/less ${pkgs.writeText "niri-keybindings.txt" ''
      Niri Keybindings Reference

      Window Management:
      Super + T                 Open terminal
      Super + D                 Open application launcher
      Super + Q                 Close window
      Super + F                 Maximize column
      Super + Shift + F         Fullscreen window
      Super + C                 Center column

      Navigation:
      Super + Left/H            Focus column left
      Super + Right/L           Focus column right
      Super + Up/K              Focus window up
      Super + Down/J            Focus window down
      Super + Home              Focus first column
      Super + End               Focus last column

      Moving Windows:
      Super + Ctrl + Left/H     Move column left
      Super + Ctrl + Right/L    Move column right
      Super + Ctrl + Up/K       Move window up
      Super + Ctrl + Down/J     Move window down
      Super + Ctrl + Home       Move column to first
      Super + Ctrl + End        Move column to last

      Workspaces (Scrollable):
      Super + Page_Up/I         Focus workspace up
      Super + Page_Down/U       Focus workspace down
      Super + Scroll Up         Focus workspace up
      Super + Scroll Down       Focus workspace down
      Super + 1-9               Focus workspace 1-9

      Multi-Monitor:
      Super + Shift + Left/H    Focus monitor left
      Super + Shift + Right/L   Focus monitor right
      Super + Shift + Up/K      Focus monitor up
      Super + Shift + Down/J    Focus monitor down

      Column Management:
      Super + R                 Switch preset column width
      Super + Minus             Decrease column width
      Super + Equal             Increase column width
      Super + Comma             Consume window into column
      Super + Period            Expel window from column

      System:
      Super + Shift + E         Quit niri
      Super + Shift + P         Power off monitors
      Super + Ctrl + L          Lock screen
      Print                     Screenshot
      Super + Print             Screenshot to clipboard

      Audio/Brightness:
      Volume Up/Down            Adjust volume
      Brightness Up/Down        Adjust brightness
    ''}";
    icon = "preferences-desktop-keyboard";
    categories = [
      "System"
      "Documentation"
    ];
  };

  # niri itself, as structured settings from niri-flake's Home Manager module.
  #
  # This replaces a 228-line KDL blob that modules/desktop/niri.nix wrote to
  # /etc/niri/config.kdl. Neither nixpkgs nor home-manager ships a niri module,
  # which is why that string existed; niri-flake supplies one, so the config is
  # now typed and a host can override a single binding.
  programs.niri = {
    enable = true;
    # niri-flake's own "stable" is 25.08, older than the niri in our pinned
    # nixpkgs, so take the package from nixpkgs and use the flake for its module.
    package = pkgs.niri;

    settings = {
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      hotkey-overlay.skip-at-startup = false;

      input = {
        keyboard = {
          xkb.layout = "us";
          repeat-delay = 600;
          repeat-rate = 25;
        };
        mouse = {
          natural-scroll = false;
          accel-speed = 0.0;
          accel-profile = "flat";
        };
        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = true;
          click-method = "clickfinger";
        };
      };

      layout = {
        gaps = 16;
        center-focused-column = "never";
        preset-column-widths = [
          { proportion = 1.0 / 3.0; }
          { proportion = 1.0 / 2.0; }
          { proportion = 2.0 / 3.0; }
        ];
        default-column-width.proportion = 1.0 / 2.0;
      };

      # ponytail: outputs are left to niri's autodetection. Override per host:
      #   programs.niri.settings.outputs."DP-1" = { mode = { width = 2560; ... }; };

      # Carried over from the old placeholder config.kdl this profile used to
      # write; now typed instead of a KDL string.
      window-rules = [
        {
          matches = [ { app-id = "firefox"; } ];
          default-column-width.proportion = 0.75;
        }
        {
          matches = [ { app-id = "code"; } ];
          default-column-width.proportion = 0.6;
        }
      ];

      spawn-at-startup = [
        { command = [ "waybar" ]; }
        { command = [ "dunst" ]; }
      ];

      binds =
        with config.lib.niri.actions;
        let
          # niri has no shell behind `spawn`, so a pipeline needs spawn-sh.
          # The old config used spawn with "$(slurp)" and "|" as literal argv,
          # which silently never worked.
          sh = spawn-sh;
        in
        {
          "Mod+Shift+Slash".action = show-hotkey-overlay;

          "Mod+T".action = spawn "alacritty";
          "Mod+D".action = spawn "fuzzel";
          "Mod+Q".action = close-window;
          "Mod+Ctrl+L".action = spawn "swaylock";

          "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
          "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
          "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86MonBrightnessUp".action = sh "brightnessctl set 10%+";
          "XF86MonBrightnessDown".action = sh "brightnessctl set 10%-";

          "Print".action = sh "grim -g \"$(slurp)\" - | wl-copy";
          "Mod+Print".action = sh "grim - | wl-copy";

          "Mod+Left".action = focus-column-left;
          "Mod+Right".action = focus-column-right;
          "Mod+Up".action = focus-window-up;
          "Mod+Down".action = focus-window-down;
          "Mod+H".action = focus-column-left;
          "Mod+L".action = focus-column-right;
          "Mod+K".action = focus-window-up;
          "Mod+J".action = focus-window-down;

          "Mod+Ctrl+Left".action = move-column-left;
          "Mod+Ctrl+Right".action = move-column-right;
          "Mod+Ctrl+Up".action = move-window-up;
          "Mod+Ctrl+Down".action = move-window-down;
          "Mod+Ctrl+H".action = move-column-left;
          "Mod+Ctrl+K".action = move-window-up;
          "Mod+Ctrl+J".action = move-window-down;

          "Mod+Home".action = focus-column-first;
          "Mod+End".action = focus-column-last;
          "Mod+Ctrl+Home".action = move-column-to-first;
          "Mod+Ctrl+End".action = move-column-to-last;

          "Mod+Shift+Left".action = focus-monitor-left;
          "Mod+Shift+Right".action = focus-monitor-right;
          "Mod+Shift+Up".action = focus-monitor-up;
          "Mod+Shift+Down".action = focus-monitor-down;
          "Mod+Shift+H".action = focus-monitor-left;
          "Mod+Shift+L".action = focus-monitor-right;
          "Mod+Shift+K".action = focus-monitor-up;
          "Mod+Shift+J".action = focus-monitor-down;

          "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
          "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
          "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
          "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;

          "Mod+Page_Down".action = focus-workspace-down;
          "Mod+Page_Up".action = focus-workspace-up;
          "Mod+U".action = focus-workspace-down;
          "Mod+I".action = focus-workspace-up;

          "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
          "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
          "Mod+Ctrl+U".action = move-column-to-workspace-down;
          "Mod+Ctrl+I".action = move-column-to-workspace-up;

          "Mod+Shift+Page_Down".action = move-workspace-down;
          "Mod+Shift+Page_Up".action = move-workspace-up;
          "Mod+Shift+U".action = move-workspace-down;
          "Mod+Shift+I".action = move-workspace-up;

          "Mod+WheelScrollDown" = {
            action = focus-workspace-down;
            cooldown-ms = 150;
          };
          "Mod+WheelScrollUp" = {
            action = focus-workspace-up;
            cooldown-ms = 150;
          };
          "Mod+Ctrl+WheelScrollDown" = {
            action = move-column-to-workspace-down;
            cooldown-ms = 150;
          };
          "Mod+Ctrl+WheelScrollUp" = {
            action = move-column-to-workspace-up;
            cooldown-ms = 150;
          };

          "Mod+WheelScrollRight".action = focus-column-right;
          "Mod+WheelScrollLeft".action = focus-column-left;
          "Mod+Ctrl+WheelScrollRight".action = move-column-right;
          "Mod+Ctrl+WheelScrollLeft".action = move-column-left;

          "Mod+Comma".action = consume-window-into-column;
          "Mod+Period".action = expel-window-from-column;

          "Mod+R".action = switch-preset-column-width;
          "Mod+F".action = maximize-column;
          "Mod+Shift+F".action = fullscreen-window;
          "Mod+C".action = center-column;

          "Mod+Minus".action = set-column-width "-10%";
          "Mod+Equal".action = set-column-width "+10%";
          "Mod+Shift+Minus".action = set-window-height "-10%";
          "Mod+Shift+Equal".action = set-window-height "+10%";

          "Mod+Shift+E".action = quit;
          "Mod+Shift+P".action = power-off-monitors;
          "Mod+Shift+Ctrl+T".action = toggle-debug-tint;
        }
        # Mod+N focuses workspace N, Mod+Ctrl+N moves the column there.
        // builtins.listToAttrs (
          builtins.concatMap (i: [
            {
              name = "Mod+${toString i}";
              value.action = focus-workspace i;
            }
          ]) (builtins.genList (n: n + 1) 9)
        );
    };
  };
}
