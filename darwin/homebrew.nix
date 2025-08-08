# Homebrew Configuration for nix-darwin
# Manages Homebrew packages, casks, and Mac App Store apps

{ pkgs, ... }:

{
  # Enable Homebrew integration with nix-darwin
  homebrew = {
    enable = true;

    # Homebrew settings
    global = {
      brewfile = true; # Use Brewfile for dependency management
      lockfiles = true; # Create Brewfile.lock.json
    };

    # Auto-upgrade and cleanup settings
    onActivation = {
      autoUpdate = true; # Update Homebrew during system activation
      upgrade = true; # Upgrade packages during activation
      cleanup = "zap"; # Remove all unmanaged packages and casks
    };

    # Command line tools (brews)
    brews = [
      # Development tools not available in Nix or better via Homebrew
      "mas" # Mac App Store CLI (for installing Mac App Store apps)

      # Media tools
      "ffmpeg" # Sometimes better compatibility than Nix version
      "youtube-dl" # Video downloader

      # macOS-specific tools
      "switchaudio-osx" # Audio device switching
      "codewhisperer" # AWS CodeWhisperer CLI

      # Optional: Remove if you prefer Nix versions
      # "git"            # Often prefer Homebrew git on macOS
      # "node"           # Node.js (comment out if using Nix)
      # "python@3.11"    # Python (comment out if using Nix)
    ];

    # GUI Applications (casks)
    casks = [
      # Development tools
      "visual-studio-code" # Code editor
      "docker" # Docker Desktop
      "postman" # API testing
      "github-desktop" # Git GUI
      "sourcetree" # Git GUI alternative

      # Browsers
      "firefox" # Firefox browser
      "google-chrome" # Chrome browser
      "brave-browser" # Privacy-focused browser

      # Productivity
      "notion" # Note-taking and collaboration
      "slack" # Team communication
      "discord" # Community chat
      "zoom" # Video conferencing
      "obsidian" # Knowledge management

      # Media and design
      "figma" # Design tool
      "vlc" # Media player
      "imageoptim" # Image compression
      "keka" # Archive utility

      # System utilities
      "raycast" # Spotlight replacement
      "alfred" # Productivity app (alternative to Raycast)
      "rectangle" # Window management
      "bartender-4" # Menu bar management
      "cleanmymac" # System maintenance
      "the-unarchiver" # Archive extraction
      "appcleaner" # Application uninstaller

      # Development infrastructure
      "orbstack" # Docker and Linux containers
      "utm" # Virtual machines (for NixOS VMs!)
      "parallels-desktop" # Virtual machines (commercial)

      # Database tools
      "dbeaver-community" # Database management
      "redis-insight" # Redis GUI
      "mongodb-compass" # MongoDB GUI

      # Text editors and IDEs
      "sublime-text" # Text editor
      "jetbrains-toolbox" # JetBrains IDEs manager

      # Cloud storage
      "dropbox" # Cloud storage
      "google-drive" # Google Drive
      "onedrive" # Microsoft OneDrive

      # Security and privacy
      "1password" # Password manager
      "protonvpn" # VPN client
      "malwarebytes" # Security software

      # Communication
      "telegram" # Messaging
      "whatsapp" # Messaging
      "signal" # Private messaging

      # Entertainment
      "spotify" # Music streaming
      "netflix" # Video streaming

      # Fonts (if not managed by Nix)
      "font-fira-code" # Programming font
      "font-jetbrains-mono" # Programming font
      "font-source-code-pro" # Programming font
    ];

    # Mac App Store applications
    masApps = {
      # Productivity
      "Keynote" = 409183694;
      "Numbers" = 409203825;
      "Pages" = 409201541;

      # Development
      "Xcode" = 497799835;
      "TestFlight" = 899247664;

      # Utilities
      "Amphetamine" = 937984704; # Keep Mac awake
      "The Unarchiver" = 425424353; # Archive utility
      "Magnet" = 441258766; # Window management
      "CleanMyMac X" = 1339170533; # System cleaner

      # Design and media
      "Pixelmator Pro" = 1289583905; # Image editor
      "Final Cut Pro" = 424389933; # Video editor
      "Logic Pro" = 634148309; # Audio editor

      # Communication
      "Slack for Desktop" = 803453959;
      "Telegram" = 747648890;
      "WhatsApp Desktop" = 1147396723;

      # Entertainment
      "Netflix" = 1147396723;
      "Spotify" = 1147396723;

      # Note: Some apps may not be available in all regions
      # Remove or comment out apps not available in your region
    };

    # Homebrew taps (third-party repositories)
    taps = [
      "homebrew/cask" # GUI applications
      "homebrew/cask-fonts" # Fonts
      "homebrew/services" # Service management
      "homebrew/cask-versions" # Alternative versions
      "hashicorp/tap" # HashiCorp tools
      "aws/tap" # AWS tools
      "microsoft/git" # Microsoft Git tools
    ];

    # Additional Homebrew configuration
    extraConfig = ''
      # Homebrew analytics opt-out (for privacy)
      export HOMEBREW_NO_ANALYTICS=1
      
      # Auto-cleanup settings
      export HOMEBREW_INSTALL_CLEANUP=1
      
      # Brewfile settings
      export HOMEBREW_BUNDLE_FILE_GLOBAL=~/.config/Brewfile
    '';
  };

  # Environment variables for Homebrew integration
  environment.variables = {
    # Ensure Homebrew paths are available
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

  # System packages that complement Homebrew
  environment.systemPackages = with pkgs; [
    # Homebrew management tools
    (writeShellScriptBin "brew-update-all" ''
      echo "🍺 Updating Homebrew..."
      brew update
      brew upgrade
      brew cleanup
      echo "✅ Homebrew update complete!"
    '')

    (writeShellScriptBin "brew-doctor-check" ''
      echo "🔍 Running Homebrew doctor..."
      brew doctor
      echo "🧹 Running Homebrew cleanup..."
      brew cleanup
      echo "✅ Homebrew maintenance complete!"
    '')

    (writeShellScriptBin "mas-outdated" ''
      echo "📱 Checking Mac App Store updates..."
      mas outdated
    '')

    (writeShellScriptBin "mas-upgrade-all" ''
      echo "📱 Updating all Mac App Store apps..."
      mas upgrade
      echo "✅ Mac App Store updates complete!"
    '')
  ];
}
