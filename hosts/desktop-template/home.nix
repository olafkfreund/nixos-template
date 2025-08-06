# Desktop Home Manager Configuration  
# Full-featured configuration for desktop productivity
{ config, pkgs, lib, ... }:

{
  # Home Manager basics
  home = {
    username = "user";
    homeDirectory = lib.mkForce "/home/user";
    stateVersion = "25.05";
    
    packages = with pkgs; [
      # Productivity applications
      firefox
      chromium
      thunderbird
      libreoffice
      evince
      
      # Development tools
      vscode
      git
      vim
      jetbrains.idea-community
      
      # Media and creativity
      gimp
      inkscape
      blender
      audacity
      vlc
      obs-studio
      
      # Communication
      discord
      signal-desktop
      slack
      
      # System utilities
      htop
      tree
      file
      unzip
      wget
      curl
      gparted
      
      # Gaming
      lutris
      heroic
      steam-run
      
      # Archive tools
      p7zip
      unrar
      
      # Cloud and sync
      rclone
      syncthing
      
      # Graphics and design
      krita
      darktable
      
      # Development utilities
      docker-compose
      postman
      dbeaver-bin
    ];
    
    # Session variables
    sessionVariables = {
      EDITOR = "code";
      BROWSER = "firefox";
      TERMINAL = "gnome-terminal";
      
      # Development
      NODE_OPTIONS = "--max-old-space-size=8192";
      
      # Graphics
      NIXOS_OZONE_WL = "1";  # Enable Wayland for Electron apps
    };
  };

  # Programs configuration
  programs = {
    # Git configuration
    git = {
      enable = true;
      userName = "Desktop User";
      userEmail = "user@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;
        
        core.autocrlf = "input";
        fetch.prune = true;
        merge.conflictStyle = "diff3";
        
        # Desktop-friendly settings
        credential.helper = "store";
        rerere.enabled = true;
      };
    };

    # Enhanced bash for development
    bash = {
      enable = true;
      enableCompletion = true;
      historySize = 10000;
      historyControl = [ "ignoreboth" ];
      
      shellAliases = {
        # File operations
        ll = "ls -la";
        la = "ls -la";
        l = "ls -l";
        ".." = "cd ..";
        "..." = "cd ../..";
        
        # Git shortcuts
        "gs" = "git status";
        "ga" = "git add";
        "gc" = "git commit";
        "gp" = "git push";
        "gl" = "git pull";
        "gd" = "git diff";
        "gb" = "git branch";
        "gco" = "git checkout";
        
        # Development
        "serve" = "python -m http.server 8000";
        "json" = "python -m json.tool";
        
        # System
        "open" = "xdg-open";
        "pbcopy" = "xclip -selection clipboard";
        "pbpaste" = "xclip -selection clipboard -o";
        
        # Docker shortcuts
        "dps" = "docker ps";
        "dpa" = "docker ps -a";
        "di" = "docker images";
        "dex" = "docker exec -it";
        
        # Nix shortcuts
        "nix-search" = "nix search nixpkgs";
        "nix-shell-dev" = "nix-shell -p";
      };
      
      bashrcExtra = ''
        # Enhanced prompt with git information
        parse_git_branch() {
          git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
        }
        
        # Custom prompt with git branch
        PS1="\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w\[\033[00m\] \[\033[01;33m\]\$(parse_git_branch)\[\033[00m\]\$ "
        
        # Development aliases
        alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'
        
        # Quick project navigation
        cdp() {
          if [ -d "$HOME/Projects/$1" ]; then
            cd "$HOME/Projects/$1"
          else
            echo "Project $1 not found in ~/Projects/"
          fi
        }
        
        # Create and enter directory
        mkcd() {
          mkdir -p "$1" && cd "$1"
        }
        
        # Extract any archive
        extract() {
          if [ -f "$1" ] ; then
            case $1 in
              *.tar.bz2)   tar xjf "$1"     ;;
              *.tar.gz)    tar xzf "$1"     ;;
              *.bz2)       bunzip2 "$1"     ;;
              *.rar)       unrar x "$1"     ;;
              *.gz)        gunzip "$1"      ;;
              *.tar)       tar xf "$1"      ;;
              *.tbz2)      tar xjf "$1"     ;;
              *.tgz)       tar xzf "$1"     ;;
              *.zip)       unzip "$1"       ;;
              *.Z)         uncompress "$1"  ;;
              *.7z)        7z x "$1"        ;;
              *)           echo "'$1' cannot be extracted via extract()" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        }
        
        # Show colors
        show_colors() {
          for i in {0..255}; do
            printf "\x1b[48;5;%sm%3d\e[0m " "$i" "$i"
            if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
              printf "\n";
            fi
          done
        }
      '';
    };

    # Firefox with custom settings
    firefox = {
      enable = true;
      profiles.default = {
        id = 0;
        isDefault = true;
        settings = {
          # Performance settings
          "browser.cache.disk.enable" = true;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 102400;  # 100MB
          
          # Privacy settings
          "privacy.donottrackheader.enabled" = true;
          "privacy.trackingprotection.enabled" = true;
          "dom.security.https_only_mode" = true;
          
          # UI settings
          "browser.toolbars.bookmarks.visibility" = "always";
          "browser.tabs.drawInTitlebar" = true;
          "browser.uidensity" = 1;  # Compact
          
          # Downloads
          "browser.download.dir" = "${config.home.homeDirectory}/Downloads";
          "browser.download.useDownloadDir" = true;
          
          # Developer settings
          "devtools.theme" = "dark";
          "devtools.toolbox.host" = "right";
        };
        
        # Firefox extensions - using system firefox addons (nur not available)
        # extensions = with pkgs.firefox-addons; [
        #   ublock-origin
        #   bitwarden
        #   darkreader
        #   tree-style-tab
        #   vimium
        # ];
      };
    };

    # VS Code configuration
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        # Language support
        ms-python.python
        rust-lang.rust-analyzer
        golang.go
        ms-vscode.cpptools
        bradlc.vscode-tailwindcss
        
        # Nix support
        jnoortheen.nix-ide
        
        # Git integration
        eamodio.gitlens
        
        # Productivity
        vscodevim.vim
        # ms-vscode.vscode-todo-highlight  # Extension not available
        streetsidesoftware.code-spell-checker
        
        # Themes
        dracula-theme.theme-dracula
        pkief.material-icon-theme
        
        # Remote development
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-containers
      ];
      
      userSettings = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "JetBrains Mono";
        "editor.fontLigatures" = true;
        "editor.tabSize" = 2;
        "editor.insertSpaces" = true;
        "editor.wordWrap" = "on";
        "editor.minimap.enabled" = true;
        "editor.formatOnSave" = true;
        "editor.rulers" = [ 80 120 ];
        
        "workbench.colorTheme" = "Dracula";
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.startupEditor" = "newUntitledFile";
        
        "terminal.integrated.fontFamily" = "JetBrains Mono";
        "terminal.integrated.fontSize" = 13;
        
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;
        
        "extensions.autoUpdate" = true;
        
        # Nix settings
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        
        # File associations
        "files.associations" = {
          "*.nix" = "nix";
          "flake.lock" = "json";
        };
      };
    };

    # Direnv for project environments
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
      
      extraConfig = ''
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes
        
        # Development friendly settings
        HashKnownHosts no
        StrictHostKeyChecking ask
        
        # Connection settings
        ConnectTimeout 10
        ConnectionAttempts 3
      '';
    };

    # Zsh alternative (optional)
    fish = {
      enable = false;  # Set to true if preferred over bash
      shellInit = ''
        # Custom fish configuration would go here
      '';
    };
  };

  # Services configuration
  services = {
    # Desktop notifications
    dunst = {
      enable = true;
      settings = {
        global = {
          geometry = "400x80-30+30";
          transparency = 10;
          font = "JetBrains Mono 11";
          format = "%s %p\\n%b";
          show_age_threshold = 60;
          idle_threshold = 120;
          markup = "full";
        };
        
        urgency_low = {
          background = "#2b2b2b";
          foreground = "#ffffff";
          timeout = 5;
        };
        
        urgency_normal = {
          background = "#285577";
          foreground = "#ffffff";
          timeout = 10;
        };
        
        urgency_critical = {
          background = "#900000";
          foreground = "#ffffff";
          timeout = 0;
        };
      };
    };

    # Redshift for eye care
    redshift = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 6500;
        night = 4500;
      };
      settings = {
        redshift = {
          brightness-day = "1.0";
          brightness-night = "0.9";
        };
      };
    };

    # GPG agent
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      
      defaultCacheTtl = 3600;
      defaultCacheTtlSsh = 3600;
      maxCacheTtl = 7200;
    };

    # Syncthing for file sync
    syncthing = {
      enable = true;
      tray.enable = true;
    };

    # Desktop services
    flameshot.enable = true;  # Screenshot tool
  };

  # Desktop environment specific configuration
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      cursor-theme = "Adwaita";
      font-name = "Cantarell 11";
      document-font-name = "Cantarell 11";
      monospace-font-name = "JetBrains Mono 10";
      
      enable-hot-corners = false;
      show-battery-percentage = true;
    };
    
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      resize-with-right-button = true;
    };
    
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "org.gnome.Nautilus.desktop"
        "code.desktop"
        "org.gnome.Terminal.desktop"
        "thunderbird.desktop"
      ];
    };
    
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:escape" ];  # Caps Lock as Escape
    };
    
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>Return";
      command = "gnome-terminal";
      name = "Open Terminal";
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
        "image/jpeg" = "eog.desktop";
        "image/png" = "eog.desktop";
        
        "text/plain" = "code.desktop";
        "application/json" = "code.desktop";
        "text/x-python" = "code.desktop";
      };
    };
    
    # User directories
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      videos = "${config.home.homeDirectory}/Videos";
    };
    
    # Desktop entries for development
    desktopEntries = {
      "dev-shell" = {
        name = "Development Shell";
        comment = "Open terminal in development environment";
        exec = "gnome-terminal --working-directory=${config.home.homeDirectory}/Projects";
        icon = "terminal";
        categories = [ "Development" "System" ];
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
      gtk-button-images = 1;
      gtk-menu-images = 1;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Fonts configuration
  fonts.fontconfig.enable = true;

  # Project directories
  home.file = {
    "Projects/.keep".text = "";
    "Scripts/.keep".text = "";
    ".local/bin/.keep".text = "";
  };
}