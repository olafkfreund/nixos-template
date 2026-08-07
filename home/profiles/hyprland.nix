{ config, pkgs, ... }:

{
  # Hyprland-specific Home Manager configuration

  # Wayland/Hyprland applications
  home.packages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    wlr-randr

    # Application launcher and menus
    wofi

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
    imv # Image viewer
    mpv # Video player
    zathura # PDF viewer

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

    # Clipboard management
    clipman

    # Color picker
    hyprpicker

    # System info
    fastfetch
  ];

  # Alacritty terminal configuration
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = 0.9;
        padding = {
          x = 8;
          y = 8;
        };
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

      # Catppuccin Mocha theme
      colors = {
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };

        cursor = {
          text = "#1e1e2e";
          cursor = "#f5e0dc";
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
      };

      bell = {
        animation = "EaseOutExpo";
        duration = 0;
      };
    };
  };

  # Wofi launcher configuration
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 40;
      gtk_dark = true;
    };

    style = ''
      window {
        margin: 0px;
        border: 2px solid #cba6f7;
        background-color: #1e1e2e;
        border-radius: 8px;
      }

      #input {
        margin: 5px;
        border: 1px solid #6c7086;
        color: #cdd6f4;
        background-color: #313244;
        border-radius: 4px;
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: #1e1e2e;
      }

      #outer-box {
        margin: 5px;
        border: none;
        background-color: #1e1e2e;
      }

      #scroll {
        margin: 0px;
        border: none;
      }

      #text {
        margin: 5px;
        border: none;
        color: #cdd6f4;
      }

      #entry {
        margin: 2px;
        border: none;
        border-radius: 4px;
      }

      #entry:selected {
        background-color: #585b70;
      }

      #text:selected {
        color: #cdd6f4;
      }
    '';
  };

  # Waybar configuration (handled by system module but can be overridden)
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  # Mako notification daemon (alternative to dunst)
  services.mako = {
    enable = false; # Using dunst from system config by default
    backgroundColor = "#1e1e2e";
    borderColor = "#cba6f7";
    textColor = "#cdd6f4";
    borderRadius = 8;
    borderSize = 2;
    font = "JetBrains Mono 10";
    padding = "10";
    margin = "10";
    defaultTimeout = 5000;
  };

  # Swaylock screen locker
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      line-color = "313244";
      show-failed-attempts = true;
      image = "~/.config/wallpaper.jpg";
      scaling = "fill";
    };
  };

  # GTK theming for Wayland applications
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

  # Hyprland-specific session variables
  home.sessionVariables = {
    # Wayland
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
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
  };

  # ponytail: no hand-rolled waybar unit. programs.waybar already ships one,
  # and defining both collided on Unit.Description.

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
      };
    };
  };

  # Hyprland itself, as structured settings rather than a hand-written file.
  #
  # This replaces a 158-line hyprlang blob that modules/desktop/hyprland.nix
  # wrote to /etc/hypr/hyprland.conf. That file could not be overridden per
  # user, and inside a Nix string you get no LSP, no formatter and one extra
  # indent level on every line. Home Manager renders this attrset to hyprlang,
  # so a host can override a single binding without restating the whole config.
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true; # legacy X11 apps (Steam, older Electron) still work

    # ponytail: pinned to hyprlang (hyprland.conf), not Hyprland 0.45+'s newer
    # Lua config. Home Manager defaults to "lua" from stateVersion 26.05 and
    # renders settings.<key> straight to hl.<key>(...), which only works for
    # keys that are real Lua API functions -- general/decoration/input/dwindle
    # are not; they all go through hl.config({...}), and bindm/bindel/bindl are
    # hl.bind(keys, dispatcher, {drag|repeating|locked = true}). Porting needs
    # exact dispatcher signatures, and share/hypr/stubs types them only as
    # `fun(...)`, so they cannot be verified from the package.
    # Upgrade path: set configType = "lua" and supply a real hyprland.lua via
    # extraConfig -- Home Manager already writes a .luarc.json pointing at those
    # stubs, so that file gets full LSP.
    configType = "hyprlang";

    settings = {
      "$mod" = "SUPER";

      # Leave monitors on Hyprland's autodetection. Override per host with:
      #   wayland.windowManager.hyprland.settings.monitor = [ "DP-1,2560x1440@144,0x0,1" ];
      monitor = [ ",preferred,auto,auto" ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
        };
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
        allow_tearing = false;
      };

      # ponytail: no blur/shadow/animation block. Hyprland's defaults are fine,
      # and the old one still set drop_shadow/shadow_range/col.shadow, which
      # Hyprland removed in 0.45 (this package is 0.55.4). Theming is the
      # user's business, not the template's.
      decoration.rounding = 10;

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      bind = [
        "$mod, Q, exec, alacritty"
        "$mod, C, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, thunar"
        "$mod, V, togglefloating,"
        "$mod, R, exec, wofi --show drun"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod, B, exec, firefox"

        "$mod, Print, exec, grim - | wl-copy"
        '', Print, exec, grim -g "$(slurp)" - | wl-copy''

        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
      ]
      # 1..9 plus 0 for workspace 10, generated rather than written out twice
      ++ builtins.concatMap (
        i:
        let
          ws = toString i;
          key = if i == 10 then "0" else ws;
        in
        [
          "$mod, ${key}, workspace, ${ws}"
          "$mod SHIFT, ${key}, movetoworkspace, ${ws}"
        ]
      ) (builtins.genList (n: n + 1) 10);

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Media and brightness keys repeat while held, so they need bindel.
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
      ];

      bindl = [ ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" ];

      exec-once = [
        "waybar"
        "dunst"
      ];
    };
  };
}
