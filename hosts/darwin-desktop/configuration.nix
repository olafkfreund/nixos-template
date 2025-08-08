# nix-darwin Desktop Configuration
# Full-featured desktop configuration for macOS users

{ config, pkgs, lib, inputs, outputs, ... }:

{
  imports = [
    ../../darwin/default.nix
    ./home.nix
  ];

  # System identification
  networking.hostName = lib.mkForce "nix-darwin-desktop";
  networking.localHostName = lib.mkForce "nix-darwin-desktop";
  networking.computerName = lib.mkForce "nix-darwin Desktop";

  # Desktop-specific system packages
  environment.systemPackages = with pkgs; [
    # Development environments
    nodejs_20
    python311
    go
    rustc
    cargo

    # Development tools
    docker
    docker-compose
    kubernetes
    kubectl
    helm

    # Databases and services
    postgresql_15
    redis

    # Text editors and IDEs (CLI versions)
    vim
    neovim
    emacs

    # Media and graphics tools
    imagemagick
    ffmpeg
    gimp

    # System utilities
    htop
    btop
    iftop
    tree
    fd
    ripgrep
    bat
    eza
    zoxide
    fzf

    # Archive and compression
    unzip
    p7zip

    # Network tools
    curl
    wget
    httpie
    nmap

    # Git and version control
    git
    gh
    git-lfs
    lazygit

    # Cloud tools
    awscli2
    terraform
    ansible

    # Desktop productivity (CLI tools)
    pandoc
    texlive.combined.scheme-medium

    # Desktop-specific utilities
    (writeShellScriptBin "desktop-info" ''
      echo "🖥️  nix-darwin Desktop Information"
      echo "================================="
      echo ""
      echo "💻 System:"
      echo "  Hostname: $(hostname)"
      echo "  macOS: $(sw_vers -productVersion)"
      echo "  Architecture: $(uname -m)"
      echo "  Uptime: $(uptime | cut -d',' -f1 | cut -d' ' -f4-)"
      echo ""
      echo "🔧 Development Environment:"
      echo "  Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
      echo "  Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
      echo "  Go: $(go version 2>/dev/null | cut -d' ' -f3 || echo 'Not installed')"
      echo "  Rust: $(rustc --version 2>/dev/null | cut -d' ' -f1-2 || echo 'Not installed')"
      echo ""
      echo "📦 Package Managers:"
      echo "  Nix: $(nix --version | head -1)"
      echo "  Homebrew: $(brew --version 2>/dev/null | head -1 || echo 'Not installed')"
      echo ""
      echo "🚀 Services:"
      echo "  Docker: $(docker --version 2>/dev/null || echo 'Not running')"
      echo "  PostgreSQL: $(pg_ctl --version 2>/dev/null | head -1 || echo 'Not installed')"
      echo "  Redis: $(redis-cli --version 2>/dev/null || echo 'Not installed')"
      echo ""
      echo "💾 Storage:"
      df -h / | tail -1 | awk '{print "  Root: " $3 " used of " $2 " (" $5 " full)"}'
      echo "  Nix Store: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Unknown')"
    '')

    (writeShellScriptBin "dev-setup" ''
      echo "🚀 Development Environment Setup"
      echo "==============================="
      echo ""
      
      # Node.js project setup
      if [ -f "package.json" ]; then
        echo "📦 Node.js project detected - installing dependencies..."
        npm install
      fi
      
      # Python project setup
      if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "🐍 Python project detected - setting up virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        if [ -f "requirements.txt" ]; then
          pip install -r requirements.txt
        fi
        if [ -f "pyproject.toml" ]; then
          pip install -e .
        fi
      fi
      
      # Rust project setup
      if [ -f "Cargo.toml" ]; then
        echo "🦀 Rust project detected - building..."
        cargo build
      fi
      
      # Go project setup
      if [ -f "go.mod" ]; then
        echo "🏃 Go project detected - downloading dependencies..."
        go mod download
        go mod tidy
      fi
      
      echo "✅ Development setup complete!"
    '')

    (writeShellScriptBin "project-init" ''
      echo "📁 Project Initialization"
      echo "========================"
      echo ""
      
      read -p "Project name: " project_name
      read -p "Project type (node/python/rust/go/react/vue): " project_type
      
      if [ -z "$project_name" ]; then
        echo "❌ Project name is required"
        exit 1
      fi
      
      mkdir -p "$project_name"
      cd "$project_name"
      
      case "$project_type" in
        "node")
          npm init -y
          echo "node_modules/" > .gitignore
          echo "*.log" >> .gitignore
          ;;
        "python")
          python3 -m venv venv
          echo "venv/" > .gitignore
          echo "__pycache__/" >> .gitignore
          echo "*.pyc" >> .gitignore
          touch requirements.txt
          ;;
        "rust")
          cargo init
          ;;
        "go")
          go mod init "$project_name"
          touch main.go
          echo "# $project_name" > README.md
          ;;
        "react")
          npx create-react-app .
          ;;
        "vue")
          npm create vue@latest .
          ;;
        *)
          echo "# $project_name" > README.md
          ;;
      esac
      
      git init
      git add .
      git commit -m "Initial commit"
      
      echo "✅ Project '$project_name' initialized!"
      echo "📁 Location: $(pwd)"
    '')
  ];

  # Desktop-specific Homebrew applications
  homebrew = {
    # Additional casks for desktop use
    casks = [
      # Design and creativity
      "sketch"
      "adobe-creative-cloud"
      "canva"

      # Communication and collaboration
      "zoom"
      "microsoft-teams"
      "slack"
      "discord"

      # Development tools
      "visual-studio-code"
      "jetbrains-toolbox"
      "github-desktop"
      "tower"
      "postman"

      # Productivity
      "notion"
      "obsidian"
      "todoist"
      "calendly"

      # Media
      "spotify"
      "vlc"
      "handbrake"

      # Utilities
      "raycast"
      "rectangle"
      "bartender-4"
      "cleanmymac"
      "the-unarchiver"
    ];

    # Additional Mac App Store apps for desktop
    masApps = {
      "Xcode" = 497799835;
      "Final Cut Pro" = 424389933;
      "Logic Pro" = 634148309;
      "Pixelmator Pro" = 1289583905;
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "TestFlight" = 899247664;
    };
  };

  # Desktop-specific system settings
  system.defaults = {
    dock = {
      tilesize = 64; # Larger dock icons for desktop
      show-recents = false;
      static-only = false; # Allow running apps in dock
    };

    finder = {
      AppleShowAllFiles = true; # Show hidden files
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # Dark mode
      AppleShowScrollBars = "WhenScrolling";
    };
  };

  # Services for development
  services = {
    # Enable SSH for remote development
    # Note: SSH service is managed differently on macOS
  };

  # Time zone and locale
  time.timeZone = lib.mkDefault "America/New_York"; # Adjust as needed

  # User configuration
  users.users."${config.users.users.admin.name or "admin"}" = {
    description = "Desktop Administrator";
    shell = pkgs.zsh;
  };

  # Enable fonts
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

  # Development environment setup
  programs.zsh = {
    shellInit = lib.mkAfter ''
      # Desktop development shortcuts
      alias dev="cd ~/Development"
      alias proj="cd ~/Projects"
      alias downloads="cd ~/Downloads"
      alias desktop="cd ~/Desktop"
      
      # Development server shortcuts
      alias serve="python3 -m http.server 8000"
      alias liveserver="npx live-server"
      
      # Docker shortcuts
      alias dps="docker ps"
      alias dimg="docker images"
      alias dprune="docker system prune -f"
      
      # Git shortcuts for desktop workflow
      alias gst="git status"
      alias gco="git checkout"
      alias gcm="git commit -m"
      alias gps="git push"
      alias gpl="git pull"
      alias glog="git log --oneline --graph --decorate"
      
      # macOS-specific shortcuts
      alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
      alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder"
      alias desktop-clean="find ~/Desktop -name '.DS_Store' -delete"
      
      echo "🖥️  nix-darwin Desktop Environment Ready!"
      echo "💡 Tips:"
      echo "  • Run 'desktop-info' for system information"
      echo "  • Run 'dev-setup' in project directories for quick setup"
      echo "  • Run 'project-init' to create new projects"
    '';
  };
}
