{ config, lib, pkgs, ... }:

{
  # Niri-specific Home Manager configuration

  # Wayland/Niri applications
  home.packages = with pkgs; [
    # Wayland utilities
    wl-clipboard
    wlr-randr
    
    # Application launcher (fuzzel is great for niri)
    fuzzel
    wofi
    
    # Terminal emulators
    alacritty
    foot            # Lightweight Wayland terminal
    
    # File managers
    thunar
    nautilus
    
    # Screenshot and screen recording
    grim
    slurp
    swappy
    wf-recorder
    
    # Media and viewers
    imv             # Image viewer
    mpv             # Video player
    zathura         # PDF viewer
    
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
          { index = 16; color = "#fab387"; }
          { index = 17; color = "#f5e0dc"; }
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
  programs.foot = {
    enable = true;
    settings = {
      main = {
        term = "xterm-256color";
        font = "JetBrains Mono:size=12";
        dpi-aware = "yes";
        pad = "8x8";
      };
      
      mouse = {
        hide-when-typing = "yes";
      };
      
      colors = {
        background = "1e1e2e";
        foreground = "cdd6f4";
        
        regular0 = "45475a";  # black
        regular1 = "f38ba8";  # red
        regular2 = "a6e3a1";  # green
        regular3 = "f9e2af";  # yellow
        regular4 = "89b4fa";  # blue
        regular5 = "f5c2e7";  # magenta
        regular6 = "94e2d5";  # cyan
        regular7 = "bac2de";  # white
        
        bright0 = "585b70";   # bright black
        bright1 = "f38ba8";   # bright red
        bright2 = "a6e3a1";   # bright green
        bright3 = "f9e2af";   # bright yellow
        bright4 = "89b4fa";   # bright blue
        bright5 = "f5c2e7";   # bright magenta
        bright6 = "94e2d5";   # bright cyan
        bright7 = "a6adc8";   # bright white
      };
    };
  };

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
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        Requisite = ["graphical-session.target"];
      };
      
      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
        KillMode = "mixed";
      };
      
      Install.WantedBy = ["graphical-session.target"];
    };
    
    # Background wallpaper service
    swaybg = {
      Unit = {
        Description = "Wallpaper daemon for Wayland";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i %h/.config/wallpaper.jpg";
        Restart = "on-failure";
        RestartSec = 1;
      };
      
      Install.WantedBy = ["graphical-session.target"];
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
    
    # Create niri config directory
    configFile."niri/config.kdl".text = ''
      // Custom Niri configuration
      // This file is managed by Home Manager
      
      // You can override the system niri configuration here
      // or add user-specific settings
      
      // Example: Custom window rules for user applications
      window-rule {
          match app-id="firefox"
          default-column-width { proportion 0.75; }
      }
      
      window-rule {
          match app-id="code"
          default-column-width { proportion 0.6; }
      }
    '';
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
    exec = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.less}/bin/less ${
      pkgs.writeText "niri-keybindings.txt" ''
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
      ''
    }";
    icon = "preferences-desktop-keyboard";
    categories = [ "System" "Documentation" ];
  };
}