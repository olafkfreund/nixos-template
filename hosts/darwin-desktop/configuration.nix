# nix-darwin Desktop Configuration
# Full-featured desktop configuration for macOS users

{ config, pkgs, lib, ... }:

{
  imports = [
    ../../darwin/default.nix
    ./home.nix
  ];

  # System identification
  networking.hostName = lib.mkForce "nix-darwin-desktop";
  networking.localHostName = lib.mkForce "nix-darwin-desktop";
  networking.computerName = lib.mkForce "nix-darwin Desktop";

  # Enable Darwin package collections
  darwin.packages = {
    profiles = {
      essential = true;
      desktop = {
        enable = true;
        includeCreative = true; # Include creative tools for desktop
      };
      development = {
        enable = true;
        languages = [ "node" "python" "go" "rust" ];
        databases = true;
        docker = true;
      };
      server = {
        enable = true; # Desktop users often need server tools
        cloud = [ "aws" ];
      };
    };
  };

  # Additional desktop-specific packages not covered by collections
  environment.systemPackages = with pkgs; [
    # Desktop-specific packages that aren't in the collections
    gimp # Specific to this host

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

  # Additional desktop-specific Homebrew packages not in collections
  homebrew.casks = [
    # Host-specific applications
    "tower" # Alternative Git GUI
    "todoist" # Task management
    "calendly" # Scheduling
    "handbrake" # Video encoding
    "microsoft-teams" # Enterprise communication
  ];

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
