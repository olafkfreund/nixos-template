# nix-darwin Laptop Configuration
# Mobile-optimized configuration for MacBook users

{ config, pkgs, lib, inputs, outputs, ... }:

{
  imports = [
    ../../darwin/default.nix
    ./home.nix
  ];

  # System identification
  networking.hostName = lib.mkForce "nix-darwin-laptop";
  networking.localHostName = lib.mkForce "nix-darwin-laptop";
  networking.computerName = lib.mkForce "nix-darwin Laptop";

  # Laptop-specific system packages
  environment.systemPackages = with pkgs; [
    # Essential development tools (minimal for battery life)
    nodejs_20
    python311
    git
    
    # Lightweight editors
    vim
    neovim
    
    # System utilities optimized for mobile use
    htop
    tree
    fd
    ripgrep
    bat
    eza
    
    # Network tools for mobile connectivity
    curl
    wget
    nmap
    
    # Archive tools
    unzip
    
    # Battery and power management utilities
    (writeShellScriptBin "battery-status" ''
      echo "🔋 Battery Information"
      echo "====================="
      echo ""
      
      # Battery percentage and status
      pmset -g batt | grep -E "([0-9]+%)" | sed 's/^/  /'
      echo ""
      
      # Power source
      echo "⚡ Power Source:"
      pmset -g ps | grep "Power" | sed 's/^/  /'
      echo ""
      
      # Sleep settings
      echo "😴 Sleep Settings:"
      pmset -g | grep -E "(sleep|displaysleep|disksleep)" | sed 's/^/  /'
      echo ""
      
      # Power adapter info
      echo "🔌 Power Adapter:"
      system_profiler SPPowerDataType | grep -A 5 "Power Adapter" | sed 's/^/  /' || echo "  No adapter info available"
    '')
    
    (writeShellScriptBin "laptop-optimize" ''
      echo "💻 Laptop Optimization"
      echo "======================"
      echo ""
      
      echo "⚡ Optimizing power settings..."
      # Optimize for battery life
      sudo pmset -b displaysleep 5
      sudo pmset -b disksleep 10
      sudo pmset -b sleep 15
      sudo pmset -b hibernatemode 3
      
      # Optimize for AC power
      sudo pmset -c displaysleep 10
      sudo pmset -c disksleep 15
      sudo pmset -c sleep 30
      sudo pmset -c hibernatemode 0
      
      echo "  Power settings optimized"
      echo ""
      
      echo "🧹 Cleaning up system..."
      # Clear caches to free space
      sudo purge
      echo "  Memory purged"
      
      # Clean up Nix store
      nix-collect-garbage -d >/dev/null 2>&1 || echo "  Nix cleanup skipped (requires Nix)"
      echo "  System cleaned"
      echo ""
      
      echo "🌐 Checking network..."
      ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "  Internet: Connected" || echo "  Internet: Disconnected"
      echo ""
      
      echo "✅ Laptop optimization complete!"
    '')
    
    (writeShellScriptBin "wifi-manager" ''
      echo "📶 Wi-Fi Manager"
      echo "================"
      echo ""
      
      case "''${1:-status}" in
        "status")
          echo "Current Wi-Fi Status:"
          /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed 's/^/  /'
          ;;
        "scan")
          echo "Scanning for networks..."
          /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport scan | sed 's/^/  /'
          ;;
        "on")
          echo "Turning Wi-Fi on..."
          networksetup -setairportpower en0 on
          ;;
        "off")
          echo "Turning Wi-Fi off..."
          networksetup -setairportpower en0 off
          ;;
        *)
          echo "Usage: wifi-manager [status|scan|on|off]"
          echo "  status - Show current Wi-Fi connection"
          echo "  scan   - Scan for available networks"
          echo "  on     - Turn Wi-Fi on"
          echo "  off    - Turn Wi-Fi off"
          ;;
      esac
    '')
    
    (writeShellScriptBin "laptop-info" ''
      echo "💻 Laptop System Information"
      echo "============================"
      echo ""
      
      echo "🖥️  System:"
      echo "  Model: $(system_profiler SPHardwareDataType | grep "Model Name" | cut -d: -f2 | xargs)"
      echo "  Chip: $(system_profiler SPHardwareDataType | grep "Chip" | cut -d: -f2 | xargs)"
      echo "  Memory: $(system_profiler SPHardwareDataType | grep "Memory" | cut -d: -f2 | xargs)"
      echo "  macOS: $(sw_vers -productVersion)"
      echo ""
      
      echo "🔋 Battery:"
      pmset -g batt | grep -E "([0-9]+%)" | sed 's/^/  /'
      echo ""
      
      echo "🌐 Connectivity:"
      networksetup -getairportpower en0 | sed 's/^/  Wi-Fi: /'
      ping -c 1 -W 1000 8.8.8.8 >/dev/null 2>&1 && echo "  Internet: Connected" || echo "  Internet: Disconnected"
      echo ""
      
      echo "💾 Storage:"
      df -h / | tail -1 | awk '{print "  Available: " $4 " of " $2 " (" $5 " used)"}'
      echo ""
      
      echo "🏃 Performance:"
      echo "  CPU Temperature: $(sudo powermetrics --samplers smc_temp --sample-count 1 -n 1 | grep "CPU die temperature" | cut -d: -f2 | xargs || echo "Not available")"
      echo "  Thermal State: $(pmset -g therm | grep "CPU_Scheduler_Limit" | cut -d= -f2 || echo "Normal")"
    '')
    
    (writeShellScriptBin "dev-mobile" ''
      echo "📱 Mobile Development Setup"
      echo "=========================="
      echo ""
      
      # Check if we're on battery
      if pmset -g batt | grep -q "Battery Power"; then
        echo "🔋 Running on battery - using lightweight setup"
        
        echo "Setting up minimal development environment..."
        
        # Use lightweight alternatives
        export EDITOR="vim"
        export NODE_OPTIONS="--max-old-space-size=2048"  # Reduce memory usage
        
        # Suggest battery-friendly practices
        echo ""
        echo "💡 Battery-friendly development tips:"
        echo "  • Use vim/neovim instead of VS Code when possible"
        echo "  • Reduce Node.js memory usage: NODE_OPTIONS=\"--max-old-space-size=2048\""
        echo "  • Use 'npm run build' instead of dev servers when possible"
        echo "  • Consider using remote development (SSH to a server)"
        
      else
        echo "🔌 Running on AC power - full development setup available"
        
        # Full development setup
        export NODE_OPTIONS="--max-old-space-size=4096"
        
        echo "✅ Full development environment ready"
      fi
      
      echo ""
      echo "Current power source:"
      pmset -g ps | head -1 | sed 's/^/  /'
    '')
  ];

  # Laptop-specific Homebrew applications (essential only)
  homebrew = {
    casks = [
      # Essential development
      "visual-studio-code"
      "github-desktop"
      
      # Communication (mobile-friendly)
      "slack"
      "zoom"
      "telegram"
      
      # Productivity
      "notion"
      "obsidian"
      
      # System utilities for laptops
      "rectangle"
      "raycast"
      "the-unarchiver"
      
      # Battery management
      "coconutbattery"
      "aldente"
      
      # Network tools
      "wifi-explorer-lite"
    ];

    # Essential Mac App Store apps
    masApps = {
      "Xcode" = 497799835;
      "TestFlight" = 899247664;
      "Amphetamine" = 937984704;  # Keep Mac awake
      "Magnet" = 441258766;      # Window management
    };
  };

  # Laptop-optimized system settings
  system.defaults = {
    dock = {
      tilesize = 48;  # Smaller dock for screen space
      autohide = true;
      autohide-delay = 0.1;
      show-recents = false;
      minimize-to-application = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      ShowStatusBar = false;  # Save screen space
      CreateDesktop = false;  # Clean desktop for focus
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";  # Better for battery life
      AppleShowScrollBars = "WhenScrolling";
      
      # Faster key repeat for productivity
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      
      # Energy-saving settings
      NSWindowResizeTime = 0.001;
    };

    # Trackpad optimization for laptop use
    trackpad = {
      Clicking = true;  # Tap to click
      TrackpadThreeFingerDrag = true;  # Three-finger drag
    };

    # Energy-saving screen capture
    screencapture = {
      location = "~/Pictures/Screenshots";
      type = "png";
      disable-shadow = true;  # Smaller file sizes
    };
  };

  # Laptop-specific power management
  system.activationScripts.powerOptimization.text = ''
    # Set energy-efficient defaults
    
    # Battery power settings
    pmset -b displaysleep 5 2>/dev/null || true
    pmset -b disksleep 10 2>/dev/null || true
    pmset -b sleep 15 2>/dev/null || true
    pmset -b hibernatemode 3 2>/dev/null || true
    
    # AC power settings (more performance)
    pmset -c displaysleep 15 2>/dev/null || true
    pmset -c disksleep 30 2>/dev/null || true
    pmset -c sleep 60 2>/dev/null || true
    pmset -c hibernatemode 0 2>/dev/null || true
    
    # Enable automatic graphics switching (battery saving)
    pmset -a gpuswitch 2 2>/dev/null || true
    
    echo "Power management optimized for laptop use"
  '';

  # Time zone (often changes for mobile users)
  time.timeZone = lib.mkDefault "UTC";  # Will auto-detect based on location
  location.enable = true;  # Enable location services for automatic timezone

  # Network settings optimized for mobile connectivity
  networking = {
    dns = [
      # Fast, reliable DNS for mobile connections
      "1.1.1.1"
      "8.8.8.8"
      "1.0.0.1"
      "8.8.4.4"
    ];
  };

  # Fonts optimized for laptop screens
  fonts.packages = with pkgs; [
    (nerdfonts.override { 
      fonts = [ 
        "JetBrainsMono"  # Excellent for laptop screens
        "FiraCode"
        "Hack"
      ]; 
    })
    inter
    source-sans-pro
  ];

  # Shell configuration for mobile development
  programs.zsh = {
    shellInit = lib.mkAfter ''
      # Mobile development shortcuts
      alias battery="battery-status"
      alias optimize="laptop-optimize"
      alias wifi="wifi-manager"
      alias mobile="dev-mobile"
      
      # Quick navigation for mobile workflows
      alias proj="cd ~/Projects"
      alias desk="cd ~/Desktop"
      alias docs="cd ~/Documents"
      
      # Power-aware aliases
      alias code-lite="code --disable-extensions --disable-gpu"
      alias vim-config="vim ~/.vimrc"
      
      # Network shortcuts
      alias ip="curl -s ifconfig.me && echo"
      alias ping-test="ping -c 3 8.8.8.8"
      
      # System shortcuts
      alias cleanup="sudo purge && nix-collect-garbage -d"
      alias temp="sudo powermetrics --samplers smc_temp --sample-count 1 -n 1"
      
      # Git shortcuts for mobile
      alias gst="git status -s"  # Short status
      alias gcm="git commit -m"
      alias gps="git push"
      alias gpl="git pull"
      
      echo "💻 nix-darwin Laptop Environment Ready!"
      echo "🔋 Battery: $(pmset -g batt | grep -E "([0-9]+%)" | awk '{print $3}' | tr -d ';')"
    '';
  };
}