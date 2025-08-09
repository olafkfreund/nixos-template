# Darwin Package Collections
# Nix-darwin compatible package management combining Nix packages and Homebrew
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.darwin.packages;

  # Common package collections
  essentialPackages = with pkgs; [
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
  ];

  desktopPackages = with pkgs; [
    # Media and graphics
    imagemagick
    ffmpeg

    # Office and productivity (CLI tools)
    pandoc
    texlive.combined.scheme-medium

    # Desktop-specific utilities
    neofetch
  ];

  developmentPackages = with pkgs; [
    # Version control
    git-lfs
    lazygit

    # Text editors
    vim
    neovim
  ];

  serverPackages = with pkgs; [
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

    # Text processing for server management
    yq

    # Backup tools
    restic
    borgbackup

    # Process management
    tmux
  ];

  laptopPackages = with pkgs; [
    # Lightweight tools optimized for battery
  ];

  # Programming language packages
  nodePackages = with pkgs; [ nodejs_20 nodePackages.npm nodePackages.yarn ];
  pythonPackages = with pkgs; [ python311 python311Packages.pip python311Packages.virtualenv ];
  goPackages = with pkgs; [ go ];
  rustPackages = with pkgs; [ rustc cargo rustfmt clippy ];
  javaPackages = with pkgs; [ openjdk17 maven gradle ];
  phpPackages = with pkgs; [ php82 php82Packages.composer ];
  rubyPackages = with pkgs; [ ruby_3_2 rubyPackages_3_2.bundler ];

  # Database packages
  databasePackages = with pkgs; [ postgresql_15 mysql80 sqlite redis ];

  # Container packages
  containerPackages = with pkgs; [ docker docker-compose kubectl kubernetes-helm ];

  # Cloud provider packages
  awsPackages = with pkgs; [ awscli2 ];
  gcpPackages = with pkgs; [ google-cloud-sdk ];
  azurePackages = with pkgs; [ azure-cli ];

in
{
  options.darwin.packages = {
    profiles = {
      essential = mkEnableOption "Essential Darwin packages for all systems";

      desktop = {
        enable = mkEnableOption "Desktop packages for workstation use";
        includeCreative = mkOption {
          type = types.bool;
          default = false;
          description = "Include creative software via Homebrew";
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
    };
  };

  config = mkMerge [
    # Essential packages
    (mkIf cfg.profiles.essential {
      environment.systemPackages = essentialPackages;

      homebrew.casks = [
        # Essential GUI applications
        "firefox"
        "google-chrome"
        "the-unarchiver"
        "raycast"
        "rectangle"
        "slack"
        "telegram"
      ];

      homebrew.masApps = {
        "Amphetamine" = 937984704;
        "The Unarchiver" = 425424353;
      };
    })

    # Desktop packages
    (mkIf cfg.profiles.desktop.enable {
      environment.systemPackages = desktopPackages;

      homebrew.casks = [
        "visual-studio-code"
        "github-desktop"
        "postman"
        "figma"
        "canva"
      ] ++ optionals cfg.profiles.desktop.includeCreative [
        "adobe-creative-cloud"
        "sketch"
        "pixelmator-pro"
      ];

      homebrew.masApps = {
        "Keynote" = 409183694;
        "Numbers" = 409203825;
        "Pages" = 409201541;
        "Xcode" = 497799835;
        "TestFlight" = 899247664;
        "Pixelmator Pro" = 1289583905;
      } // optionalAttrs cfg.profiles.desktop.includeCreative {
        "Final Cut Pro" = 424389933;
        "Logic Pro" = 634148309;
      };

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
      environment.systemPackages = developmentPackages
        # Programming languages
        ++ optionals (elem "node" cfg.profiles.development.languages) nodePackages
        ++ optionals (elem "python" cfg.profiles.development.languages) pythonPackages
        ++ optionals (elem "go" cfg.profiles.development.languages) goPackages
        ++ optionals (elem "rust" cfg.profiles.development.languages) rustPackages
        ++ optionals (elem "java" cfg.profiles.development.languages) javaPackages
        ++ optionals (elem "php" cfg.profiles.development.languages) phpPackages
        ++ optionals (elem "ruby" cfg.profiles.development.languages) rubyPackages
        # Database tools
        ++ optionals cfg.profiles.development.databases databasePackages
        # Container tools
        ++ optionals cfg.profiles.development.docker containerPackages;

      homebrew.taps = [
        "hashicorp/tap"
      ];

      homebrew.casks = [
        "visual-studio-code"
        "jetbrains-toolbox"
        "github-desktop"
        "sourcetree"
        "postman"
        "tableplus"
        "redis-insight"
      ] ++ optionals cfg.profiles.development.docker [
        "docker"
        "orbstack"
      ];

      homebrew.brews = [
        "terraform"
        "ansible"
      ];
    })

    # Server packages
    (mkIf cfg.profiles.server.enable {
      environment.systemPackages = serverPackages
        # Cloud tools
        ++ optionals (elem "aws" cfg.profiles.server.cloud) awsPackages
        ++ optionals (elem "gcp" cfg.profiles.server.cloud) gcpPackages
        ++ optionals (elem "azure" cfg.profiles.server.cloud) azurePackages;

      homebrew.taps = [
        "aws/tap"
        "microsoft/git"
      ];

      homebrew.brews = [
        "postgresql"
        "redis"
        "nginx"
      ];

      homebrew.casks = [
        "pgadmin4"
        "redis-insight"
        "mongodb-compass"
      ];
    })

    # Laptop packages
    (mkIf cfg.profiles.laptop.enable {
      homebrew.casks = mkIf cfg.profiles.laptop.batteryOptimized [
        "coconutbattery"
        "aldente"
        "rectangle"
      ];
    })

    # Security tools via Homebrew
    (mkIf cfg.homebrew.enableExtraSecurityTools {
      homebrew.casks = [
        "1password"
        "malwarebytes"
        "protonvpn"
        "lulu"
      ];
    })

    # Environment variables and utilities for all Darwin systems
    {
      environment.systemPackages = with pkgs; [
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
