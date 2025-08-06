# Laptop Home Manager Configuration
# Optimized for mobile productivity and battery efficiency
{ pkgs, lib, ... }:

{
  # Home Manager basics
  home = {
    username = "user";
    homeDirectory = lib.mkForce "/home/user";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Productivity apps for mobile work
      firefox
      thunderbird # Email client
      libreoffice # Office suite
      evince # PDF viewer

      # Development tools (lightweight)
      git
      vim
      vscode

      # System utilities
      htop
      tree
      file
      unzip
      wget
      curl

      # Media and communication
      vlc
      signal-desktop

      # Cloud storage clients
      rclone

      # Laptop-specific utilities
      brightnessctl
      acpi
      upower
      tlp
    ];

    # Session variables for laptop use
    sessionVariables = {
      EDITOR = "vim";
      BROWSER = "firefox";

      # Reduce background processes
      NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
    };
  };

  # Programs configuration
  programs = {
    # Git configuration
    git = {
      enable = true;
      userName = "Laptop User";
      userEmail = "user@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;

        # Laptop-friendly settings
        core.autocrlf = "input";
        push.autoSetupRemote = true;

        # Reduce network usage
        fetch.prune = true;
        remote.origin.prune = true;
      };
    };

    # Terminal configuration
    bash = {
      enable = true;
      enableCompletion = true;
      historySize = 10000;
      historyControl = [ "ignoreboth" ];

      shellAliases = {
        ll = "ls -la";
        la = "ls -la";
        l = "ls -l";
        ".." = "cd ..";
        "..." = "cd ../..";

        # Power management aliases
        "battery" = "acpi -b";
        "thermal" = "acpi -t";
        "powersave" = "sudo tlp bat";
        "performance" = "sudo tlp ac";

        # Brightness control
        "bright" = "brightnessctl";
        "dim" = "brightnessctl set 50%";
        "bright-max" = "brightnessctl set 100%";
      };

      bashrcExtra = ''
        # Show battery status in prompt
        show_battery() {
          if command -v acpi >/dev/null 2>&1; then
            local battery=$(acpi -b 2>/dev/null | cut -d',' -f2 | tr -d ' ')
            if [[ -n "$battery" ]]; then
              echo "[$battery]"
            fi
          fi
        }
        
        # Custom prompt with battery indicator
        PS1="\[\033[01;32m\]\u@\h\[\033[00m\] \$(show_battery) \[\033[01;34m\]\w\[\033[00m\]\$ "
        
        # Auto-adjust screen brightness based on time
        auto_brightness() {
          local hour=$(date +%H)
          if [[ $hour -gt 18 || $hour -lt 8 ]]; then
            brightnessctl set 30% >/dev/null 2>&1
          else
            brightnessctl set 70% >/dev/null 2>&1
          fi
        }
        
        # Call auto_brightness when opening new terminal
        auto_brightness
      '';
    };

    # Direnv for development
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    # SSH configuration
    ssh = {
      enable = true;
      controlMaster = "auto";
      controlPersist = "10m";

      # Mobile-friendly SSH settings
      extraConfig = ''
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        
        # Reduce connection attempts for faster failures
        ConnectTimeout 10
        ConnectionAttempts 2
      '';
    };

    # Firefox configuration
    firefox = {
      enable = true;
      profiles.default = {
        id = 0;
        isDefault = true;
        settings = {
          # Battery-friendly settings
          "dom.ipc.processCount" = 4; # Limit content processes
          "browser.tabs.remote.autostart" = true;

          # Privacy settings for mobile use
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;

          # Performance settings
          "browser.cache.disk.enable" = true;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 51200; # 50MB RAM cache

          # Reduce background activity
          "browser.sessionstore.interval" = 30000; # 30 seconds
          "browser.tabs.animate" = false;
          "browser.fullscreen.animateUp" = 0;

          # Dark mode preference (better for battery on OLED screens)
          "ui.systemUsesDarkTheme" = 1;
        };
      };
    };
  };

  # Services configuration
  services = {
    # Battery notifications
    dunst = {
      enable = true;
      settings = {
        global = {
          geometry = "300x60-30+20";
          transparency = 10;
          font = "Noto Sans 10";
          format = "%s %p\\n%b";
          show_age_threshold = 60;
          idle_threshold = 120;
        };

        urgency_low = {
          background = "#1d2021";
          foreground = "#a89984";
          timeout = 10;
        };

        urgency_normal = {
          background = "#458588";
          foreground = "#ebdbb2";
          timeout = 10;
        };

        urgency_critical = {
          background = "#cc241d";
          foreground = "#ebdbb2";
          timeout = 0;
        };
      };
    };

    # Redshift for eye strain reduction
    redshift = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 6500;
        night = 3500;
      };
      settings = {
        redshift = {
          brightness-day = "1.0";
          brightness-night = "0.8";
        };
      };
    };

    # GPG agent configuration
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gtk2;

      # Laptop-friendly timeouts
      defaultCacheTtl = 3600; # 1 hour
      defaultCacheTtlSsh = 3600; # 1 hour
      maxCacheTtl = 7200; # 2 hours
    };

    # Syncthing for file synchronization
    syncthing = {
      enable = true;
      tray.enable = true;
    };
  };

  # Desktop environment specific configuration
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";

      # Power-saving settings
      enable-animations = false; # Disable animations to save power
    };

    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 300; # 5 minutes
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "suspend";
      sleep-inactive-battery-timeout = 900; # 15 minutes
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = lib.hm.gvariant.mkUint32 0; # Lock immediately
    };
  };

  # XDG configuration
  xdg = {
    enable = true;

    # Default applications
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";

        "application/pdf" = "evince.desktop";

        "text/plain" = "org.gnome.TextEditor.desktop";
      };
    };

    # Desktop entries for custom laptop utilities
    desktopEntries = {
      battery-info = {
        name = "Battery Information";
        comment = "Show detailed battery information";
        exec = "${pkgs.gnome-terminal}/bin/gnome-terminal -- ${pkgs.acpi}/bin/acpi -bi";
        icon = "battery";
        categories = [ "System" "Monitor" ];
      };

      power-settings = {
        name = "Power Settings";
        comment = "Quick access to power management";
        exec = "${pkgs.gnome-control-center}/bin/gnome-control-center power";
        icon = "preferences-system-power";
        categories = [ "Settings" "System" ];
      };
    };
  };

  # GTK configuration
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
    };
    iconTheme = {
      name = "Adwaita";
    };
    cursorTheme = {
      name = "Adwaita";
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Systemd user services
  systemd.user.services = {
    # Battery level monitor
    battery-monitor = {
      Unit = {
        Description = "Battery Level Monitor";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScript "battery-monitor" ''
          #!/bin/bash
          while true; do
            battery_level=$(${pkgs.acpi}/bin/acpi -b | grep -P -o '[0-9]+(?=%)')
            if [[ $battery_level -le 20 ]]; then
              ${pkgs.libnotify}/bin/notify-send -u critical "Battery Low" "Battery level: $battery_level%"
            elif [[ $battery_level -le 10 ]]; then
              ${pkgs.libnotify}/bin/notify-send -u critical "Battery Critical" "Battery level: $battery_level% - Connect charger immediately!"
            fi
            sleep 300  # Check every 5 minutes
          done
        ''}";
        Restart = "always";
        RestartSec = 10;
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
