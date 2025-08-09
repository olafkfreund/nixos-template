# Darwin Package Collections
# Comprehensive package management for nix-darwin systems combining Nix packages and Homebrew
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.packages.darwin;

  # Common Homebrew configuration shared across all profiles
  baseHomebrew = {
    enable = true;

    global = {
      brewfile = true;
      lockfiles = true;
    };

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    # Base taps needed across all profiles
    taps = [
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/services"
      "homebrew/cask-versions"
    ];

    # Environment configuration
    extraConfig = ''
      export HOMEBREW_NO_ANALYTICS=1
      export HOMEBREW_INSTALL_CLEANUP=1
      export HOMEBREW_BUNDLE_FILE_GLOBAL=~/.config/Brewfile
    '';
  };

in
{
  options.packages.darwin = {
    profiles = {
      essential = {
        enable = mkEnableOption "Essential Darwin packages for all systems";
        includeHomebrew = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to include Homebrew packages";
        };
      };

      desktop = {
        enable = mkEnableOption "Desktop packages for workstation use";
        includeCreative = mkOption {
          type = types.bool;
          default = false;
          description = "Include creative software (Adobe, Sketch, etc.)";
        };
      };

      development = {
        enable = mkEnableOption "Development packages and tools";
        languages = mkOption {
          type = types.listOf (types.enum [ "node" "python" "go" "rust" "java" "php" "ruby" ]);
          default = [ "node" "python" ];
          description = "Programming languages to include";
        };
        databases = mkOption {
          type = types.bool;
          default = true;
          description = "Include database tools and clients";
        };
        docker = mkOption {
          type = types.bool;
          default = true;
          description = "Include Docker and containerization tools";
        };
      };

      server = {
        enable = mkEnableOption "Server administration packages";
        cloud = mkOption {
          type = types.listOf (types.enum [ "aws" "gcp" "azure" "digitalocean" ]);
          default = [ "aws" ];
          description = "Cloud provider tools to include";
        };
      };

      laptop = {
        enable = mkEnableOption "Laptop-optimized package selection";
        batteryOptimized = mkOption {
          type = types.bool;
          default = true;
          description = "Use battery-optimized versions when available";
        };
      };
    };

    homebrew = {
      enableExtraSecurityTools = mkOption {
        type = types.bool;
        default = false;
        description = "Enable additional security-focused Homebrew packages";
      };

      enableGameDevelopment = mkOption {
        type = types.bool;
        default = false;
        description = "Enable game development tools via Homebrew";
      };
    };
  };

  config = mkMerge [
    # Essential packages - always installed
    (mkIf cfg.profiles.essential.enable {
      environment.systemPackages = with pkgs; [
        # Core system utilities
        coreutils
        findutils
        gnugrep
        gnused
        gawk
        curl
        wget

        # Archive and compression
        unzip
        p7zip

        # Text processing
        ripgrep
        fd
        bat
        jq

        # System monitoring
        htop
        tree

        # Network tools
        nmap

        # Git (always essential)
        git
        gh

        # Shell and terminal
        zsh
        tmux

        # Essential macOS utilities
        (writeShellScriptBin "mac-info" ''
          echo "🍎 macOS System Information"
          echo "=========================="
          echo ""
          echo "💻 Hardware:"
          echo "  Model: $(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)"
          echo "  Chip: $(system_profiler SPHardwareDataType | grep "Chip" | cut -d: -f2 | xargs)"
          echo "  Memory: $(system_profiler SPHardwareDataType | grep "Memory" | cut -d: -f2 | xargs)"
          echo ""
          echo "🖥️  Software:"
          echo "  macOS: $(sw_vers -productVersion)"
          echo "  Build: $(sw_vers -buildVersion)"
          echo "  Kernel: $(uname -r)"
          echo ""
          echo "📦 Package Managers:"
          echo "  Nix: $(nix --version | head -1)"
          echo "  Homebrew: $(brew --version 2>/dev/null | head -1 || echo 'Not installed')"
          echo ""
          echo "💾 Storage:"
          df -h / | tail -1 | awk '{print "  Root: " $4 " available of " $2 " (" $5 " used)"}'
          echo "  Nix Store: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Unknown')"
        '')
      ];

      homebrew = mkIf cfg.profiles.essential.includeHomebrew (baseHomebrew // {
        # Essential CLI tools better from Homebrew
        brews = [
          "mas" # Mac App Store CLI
        ];

        # Essential GUI applications
        casks = [
          # Browsers
          "firefox"
          "google-chrome"

          # System utilities
          "the-unarchiver"
          "raycast"
          "rectangle"

          # Communication
          "slack"
          "telegram"
        ];

        # Essential Mac App Store apps
        masApps = {
          "Amphetamine" = 937984704; # Keep Mac awake
          "The Unarchiver" = 425424353; # Archive utility
        };
      });
    })

    # Desktop packages
    (mkIf cfg.profiles.desktop.enable {
      environment.systemPackages = with pkgs; [
        # Media and graphics
        imagemagick
        ffmpeg

        # Office and productivity (CLI tools)
        pandoc
        texlive.combined.scheme-medium

        # Desktop-specific utilities
        neofetch

        (writeShellScriptBin "desktop-setup" ''
          echo "🖥️  Desktop Environment Setup"
          echo "============================="
          echo ""
          
          # Create standard directories
          mkdir -p ~/Development ~/Projects ~/Screenshots
          
          # Configure screenshot location
          defaults write com.apple.screencapture location ~/Screenshots
          defaults write com.apple.screencapture type png
          defaults write com.apple.screencapture disable-shadow -bool true
          
          # Configure Dock for desktop use
          defaults write com.apple.dock tilesize -int 64
          defaults write com.apple.dock show-recents -bool false
          
          # Enable dark mode
          defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
          
          # Finder settings
          defaults write com.apple.finder AppleShowAllFiles -bool true
          defaults write com.apple.finder ShowPathbar -bool true
          defaults write com.apple.finder ShowStatusBar -bool true
          
          # Restart affected applications
          killall Dock 2>/dev/null || true
          killall Finder 2>/dev/null || true
          killall SystemUIServer 2>/dev/null || true
          
          echo "✅ Desktop setup complete!"
          echo "📁 Created directories: ~/Development, ~/Projects, ~/Screenshots"
          echo "🖼️  Screenshots will be saved to ~/Screenshots"
        '')
      ];

      homebrew = baseHomebrew // {
        casks = [
          # Development tools
          "visual-studio-code"
          "github-desktop"
          "postman"

          # Design and creativity
          "figma"
          "canva"
        ] ++ optionals cfg.profiles.desktop.includeCreative [
          "adobe-creative-cloud"
          "sketch"
          "pixelmator-pro"
        ];

        masApps = {
          # iWork suite
          "Keynote" = 409183694;
          "Numbers" = 409203825;
          "Pages" = 409201541;

          # Development
          "Xcode" = 497799835;
          "TestFlight" = 899247664;

          # Design
          "Pixelmator Pro" = 1289583905;
        } // optionalAttrs cfg.profiles.desktop.includeCreative {
          "Final Cut Pro" = 424389933;
          "Logic Pro" = 634148309;
        };
      };

      # Desktop fonts
      fonts.packages = with pkgs; [
        (nerdfonts.override {
          fonts = [
            "FiraCode"
            "JetBrainsMono"
            "Hack"
            "SourceCodePro"
            "Inconsolata"
          ];
        })
        inter
        source-sans-pro
        source-serif-pro
        lato
        roboto
      ];
    })

    # Development packages
    (mkIf cfg.profiles.development.enable {
      environment.systemPackages = with pkgs; [
        # Version control
        git-lfs
        lazygit

        # Text editors
        vim
        neovim

        # Development utilities
        (writeShellScriptBin "dev-env-setup" ''
          echo "🚀 Development Environment Setup"
          echo "==============================="
          echo ""
          
          # Create development directories
          mkdir -p ~/Development/{projects,experiments,scripts,tools}
          
          # Git global configuration
          echo "⚙️  Configuring Git..."
          git config --global init.defaultBranch main
          git config --global pull.rebase true
          git config --global push.autoSetupRemote true
          
          # Development aliases
          echo "Creating development aliases..."
          
          echo "✅ Development environment ready!"
          echo "📁 Development directories created in ~/Development/"
        '')
      ]
      # Programming languages
      ++ optionals (elem "node" cfg.profiles.development.languages) [
        nodejs_20
        nodePackages.npm
        nodePackages.yarn
      ]
      ++ optionals (elem "python" cfg.profiles.development.languages) [
        python311
        python311Packages.pip
        python311Packages.virtualenv
      ]
      ++ optionals (elem "go" cfg.profiles.development.languages) [
        go
      ]
      ++ optionals (elem "rust" cfg.profiles.development.languages) [
        rustc
        cargo
        rustfmt
        clippy
      ]
      ++ optionals (elem "java" cfg.profiles.development.languages) [
        openjdk17
        maven
        gradle
      ]
      ++ optionals (elem "php" cfg.profiles.development.languages) [
        php82
        php82Packages.composer
      ]
      ++ optionals (elem "ruby" cfg.profiles.development.languages) [
        ruby_3_2
        rubyPackages_3_2.bundler
      ]
      # Database tools
      ++ optionals cfg.profiles.development.databases [
        postgresql_15
        mysql80
        sqlite
        redis
      ]
      # Container tools
      ++ optionals cfg.profiles.development.docker [
        docker
        docker-compose
        kubectl
        kubernetes-helm
      ];

      homebrew = baseHomebrew // {
        taps = baseHomebrew.taps ++ [
          "hashicorp/tap"
        ];

        casks = [
          # IDEs and editors
          "visual-studio-code"
          "jetbrains-toolbox"
          "github-desktop"
          "sourcetree"

          # API and database tools
          "postman"
          "tableplus"
          "redis-insight"

          # Containerization
        ] ++ optionals cfg.profiles.development.docker [
          "docker"
          "orbstack"
        ];

        brews = [
          # Development tools better from Homebrew
          "terraform"
          "ansible"
        ];
      };
    })

    # Server packages
    (mkIf cfg.profiles.server.enable {
      environment.systemPackages = with pkgs; [
        # System administration
        htop
        iotop
        nethogs
        iftop
        ncdu

        # Network tools
        netcat
        socat
        traceroute
        tcpdump

        # Log analysis
        multitail

        # Security
        nftables
        fail2ban

        # Performance monitoring
        sysstat

        # Text processing for server management
        yq

        # Backup tools
        restic
        borgbackup

        # Process management
        tmux

        # Server management utilities
        (writeShellScriptBin "server-status" ''
          echo "🖥️  Server Status Report"
          echo "======================="
          echo ""
          
          echo "📊 System Load:"
          uptime | sed 's/^/  /'
          echo ""
          
          echo "💾 Memory Usage:"
          vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+):\s+(\d+)/ and printf("  %-16s: %6.2f MB\n", $1, $2 * $size / 1048576);' | head -5
          echo ""
          
          echo "💿 Disk Usage:"
          df -h / | tail -1 | awk '{print "  Root: " $3 " used of " $2 " (" $5 " full)"}'
          echo ""
          
          echo "🌐 Network:"
          netstat -rn | grep default | head -1 | awk '{print "  Default Gateway: " $2}' || echo "  No default gateway found"
          echo ""
          
          echo "🔧 Running Services (sample):"
          ps aux | grep -E "(httpd|nginx|mysqld|postgres)" | grep -v grep | awk '{print "  " $11}' | sort | uniq || echo "  No common services detected"
        '')
      ]
      # Cloud tools
      ++ optionals (elem "aws" cfg.profiles.server.cloud) [
        awscli2
      ]
      ++ optionals (elem "gcp" cfg.profiles.server.cloud) [
        google-cloud-sdk
      ]
      ++ optionals (elem "azure" cfg.profiles.server.cloud) [
        azure-cli
      ];

      homebrew = baseHomebrew // {
        taps = baseHomebrew.taps ++ [
          "aws/tap"
          "microsoft/git"
        ];
      };
    })

    # Laptop-specific packages
    (mkIf cfg.profiles.laptop.enable {
      environment.systemPackages = with pkgs; [
        # Battery and power management
        (writeShellScriptBin "laptop-optimize" ''
          echo "💻 Laptop Optimization"
          echo "======================"
          echo ""
          
          echo "⚡ Current Power Source:"
          pmset -g ps | head -1 | sed 's/^/  /'
          echo ""
          
          echo "🔋 Battery Information:"
          pmset -g batt | grep -E "([0-9]+%)" | sed 's/^/  /'
          echo ""
          
          echo "⚙️  Optimizing power settings..."
          
          # Battery power optimization
          sudo pmset -b displaysleep 5
          sudo pmset -b disksleep 10
          sudo pmset -b sleep 15
          sudo pmset -b hibernatemode 3
          
          # AC power settings
          sudo pmset -c displaysleep 15
          sudo pmset -c disksleep 30
          sudo pmset -c sleep 60
          sudo pmset -c hibernatemode 0
          
          # Enable GPU switching for battery life
          sudo pmset -a gpuswitch 2 2>/dev/null || true
          
          echo "  Power settings optimized"
          echo ""
          
          echo "🧹 Cleaning system cache..."
          sudo purge
          echo "  Memory purged"
          echo ""
          
          echo "✅ Laptop optimization complete!"
        '')

        (writeShellScriptBin "battery-info" ''
          echo "🔋 Battery Detailed Information"
          echo "==============================="
          echo ""
          
          # Battery status and health
          pmset -g batt | sed 's/^/  /'
          echo ""
          
          # Power adapter information
          echo "🔌 Power Adapter:"
          system_profiler SPPowerDataType | grep -A 5 "Power Adapter" | sed 's/^/  /' || echo "  Not connected"
          echo ""
          
          # Thermal state
          echo "🌡️  Thermal State:"
          pmset -g therm | sed 's/^/  /'
          echo ""
          
          # Power assertions
          echo "💡 Power Assertions:"
          pmset -g assertions | grep -E "(PreventUserIdleSystemSleep|PreventSystemSleep)" | sed 's/^/  /' || echo "  None active"
        '')
      ];

      homebrew = baseHomebrew // {
        casks = mkIf cfg.profiles.laptop.batteryOptimized [
          # Battery management tools
          "coconutbattery"
          "aldente"

          # Lightweight alternatives
          "rectangle" # Instead of heavier window managers
        ];
      };
    })

    # Additional security tools via Homebrew
    (mkIf cfg.homebrew.enableExtraSecurityTools {
      homebrew.casks = [
        "1password"
        "malwarebytes"
        "protonvpn"
        "lulu" # Network monitor
      ];
    })

    # Game development tools
    (mkIf cfg.homebrew.enableGameDevelopment {
      homebrew.casks = [
        "unity"
        "blender"
        "godot"
      ];

      homebrew.masApps = {
        "Logic Pro" = 634148309; # Audio for games
      };
    })

    # Environment variables for all Darwin systems
    {
      environment.variables = {
        # Homebrew paths
        HOMEBREW_PREFIX = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local";
        HOMEBREW_CELLAR = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew/Cellar" else "/usr/local/Cellar";
        HOMEBREW_REPOSITORY = if pkgs.stdenv.hostPlatform.isAarch64 then "/opt/homebrew" else "/usr/local/Homebrew";

        # Privacy settings
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_INSECURE_REDIRECT = "1";

        # Performance settings
        HOMEBREW_INSTALL_CLEANUP = "1";
        HOMEBREW_BUNDLE_FILE_GLOBAL = "$HOME/.config/Brewfile";
      };

      # Homebrew management utilities
      environment.systemPackages = with pkgs; [
        (writeShellScriptBin "brew-maintenance" ''
          echo "🍺 Homebrew Maintenance"
          echo "======================="
          echo ""
          
          echo "📦 Updating Homebrew..."
          brew update
          echo ""
          
          echo "⬆️  Upgrading packages..."
          brew upgrade
          echo ""
          
          echo "🧹 Cleaning up..."
          brew cleanup
          brew autoremove
          echo ""
          
          echo "🏥 Running doctor..."
          brew doctor
          echo ""
          
          echo "✅ Homebrew maintenance complete!"
        '')

        (writeShellScriptBin "package-audit" ''
          echo "🔍 System Package Audit"
          echo "======================="
          echo ""
          
          echo "📦 Nix Packages:"
          nix-env -q | wc -l | awk '{print "  Installed: " $1 " packages"}'
          echo ""
          
          echo "🍺 Homebrew Packages:"
          brew list | wc -l | awk '{print "  CLI tools: " $1 " packages"}'
          brew list --cask | wc -l | awk '{print "  GUI apps: " $1 " casks"}'
          echo ""
          
          echo "📱 Mac App Store:"
          mas list | wc -l | awk '{print "  MAS apps: " $1 " applications"}'
          echo ""
          
          echo "💾 Storage Usage:"
          echo "  Nix Store: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Unknown')"
          echo "  Homebrew: $(du -sh $(brew --prefix)/Cellar 2>/dev/null | cut -f1 || echo 'Unknown')"
        '')
      ];
    }
  ];
}
