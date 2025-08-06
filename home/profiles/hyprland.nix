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
    rofi-wayland

    # Terminal emulators
    alacritty
    kitty

    # File managers
    thunar
    nautilus

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

  # User services
  systemd.user.services = {
    # Waybar
    waybar = {
      Unit = {
        Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors";
        Documentation = "https://github.com/Alexays/Waybar/wiki";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
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
      };
    };
  };
}
