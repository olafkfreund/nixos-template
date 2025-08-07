# NixOS on WSL2 Configuration Template
# Optimized for Windows Subsystem for Linux development environment

{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    # Selective module imports instead of automatic discovery
    ../../modules/core
    ../../modules/desktop
    ../../modules/development
    ../../modules/hardware
    ../../modules/services
    ../../modules/virtualization
    # Skip WSL modules for now: ../../modules/wsl
  ];

  # System identification
  networking.hostName = "nixos-wsl";

  # WSL-specific configuration
  wsl = {
    enable = true;
    defaultUser = "nixos";
    
    # Windows integration features
    startMenuLaunchers = true;  # Add GUI apps to Windows Start Menu
    interop = {
      includePath = true;       # Include Windows PATH in WSL PATH
      register = true;          # Register WSL interop
    };
    
    # Docker Desktop integration (optional)
    docker-desktop.enable = false; # Enable if using Docker Desktop
    
    # Use Windows OpenGL driver for better GPU performance
    useWindowsDriver = true;
    
    # USB/IP support for hardware devices
    usbip.enable = false; # Enable if you need USB device access
    
    # WSL configuration optimizations
    wslConf = {
      automount.root = "/mnt";
      automount.options = "metadata,uid=1000,gid=1000,umask=022,fmask=011,case=off";
      network.generateHosts = false;
      network.generateResolvConf = false;
      user.default = "nixos";
    };
  };

  # User configuration optimized for WSL development
  users = {
    # Enable mutable users for WSL (easier password management)
    mutableUsers = true;
    
    users.nixos = {
      isNormalUser = true;
      description = "NixOS WSL User";
      extraGroups = [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "docker"
        "plugdev"
      ];
      
      # Set initial password (change after first login)
      initialPassword = "nixos";
    };
  };

  # Security configuration for WSL
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false; # Convenient for WSL development
    };
    
    # AppArmor not needed in WSL
    apparmor.enable = lib.mkForce false;
    
    # Polkit for GUI applications
    polkit.enable = true;
  };

  # Network configuration for WSL
  networking = {
    # Use WSL's built-in networking
    useNetworkd = false;
    useDHCP = true;
    
    # Firewall disabled by default in WSL (Windows firewall handles this)
    firewall.enable = lib.mkForce false;
    
    # DNS configuration
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
  };

  # System services optimized for WSL
  services = {
    # SSH server for remote development
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
        X11Forwarding = true; # For GUI applications
      };
      ports = [ 22 ];
    };
    
    # D-Bus for GUI applications
    dbus.enable = true;
    
    # PulseAudio for audio (works with WSL2)
    pulseaudio = {
      enable = true;
      support32Bit = true;
      extraConfig = ''
        load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1
      '';
    };
    
    # X11 forwarding support
    xserver = {
      enable = false; # No display manager needed in WSL
      # WSL2 uses Windows display server
    };
    
    # Automatic time synchronization
    ntp.enable = true;
  };

  # Graphics and GUI support
  hardware = {
    # Graphics support for GUI applications
    graphics = {
      enable = true;
      enable32Bit = lib.mkDefault true;
    };
    
    # PulseAudio support
    pulseaudio.enable = true;
    
    # No Bluetooth in WSL
    bluetooth.enable = false;
  };

  # Development environment packages
  environment = {
    systemPackages = with pkgs; [
      # Essential development tools
      vim
      git
      wget
      curl
      unzip
      tree
      htop
      lsof
      
      # WSL-specific tools
      wslu # WSL utilities
      
      # Development tools
      nodejs
      python3
      go
      rustc
      cargo
      
      # GUI applications (will integrate with Windows)
      firefox
      vscode
      
      # System utilities
      file
      which
      man
      less
      tmux
      screen
      
      # Network tools
      netcat
      nmap
      iperf
      
      # Archive tools
      p7zip
      zip
    ];
    
    # Environment variables for WSL
    variables = {
      # Fix for GUI applications
      DISPLAY = ":0.0";
      LIBGL_ALWAYS_INDIRECT = "1";
      
      # WSL-specific paths
      WSLENV = "DISPLAY/u:LIBGL_ALWAYS_INDIRECT/u";
      
      # Development environment
      EDITOR = "vim";
      BROWSER = "/mnt/c/Program Files/Mozilla Firefox/firefox.exe";
    };
    
    # Shell aliases for Windows interop
    shellAliases = {
      # Windows command shortcuts
      explorer = "explorer.exe";
      notepad = "notepad.exe";
      code = "code.exe";
      
      # Common commands
      ll = "ls -la";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
    };
  };

  # Fonts for GUI applications
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      font-awesome
      hack-font
      fira-code
      fira-code-symbols
    ];
    
    # Font configuration for better rendering
    fontconfig = {
      enable = true;
      antialias = true;
      hinting.enable = true;
      hinting.style = "slight";
      subpixel.rgba = "rgb";
    };
  };

  # Boot configuration (WSL doesn't boot traditionally)
  boot = {
    # No bootloader needed
    loader.grub.enable = false;
    
    # Kernel modules for WSL
    kernelModules = [ ];
    
    # System control parameters
    kernel.sysctl = {
      # Network optimizations for WSL
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    };
  };

  # Systemd configuration for WSL
  systemd = {
    # WSL-specific service optimizations
    services = {
      # Disable services not needed in WSL
      systemd-resolved.enable = false;
      systemd-networkd.enable = false;
      
      # Optimize boot time
      nixos-upgrade.enable = false;
    };
    
    # User services for development
    user.services = {
      # SSH agent for development
      ssh-agent = {
        enable = true;
        description = "SSH Agent";
        wantedBy = [ "default.target" ];
      };
    };
  };

  # Locale and timezone
  time.timeZone = lib.mkDefault "UTC"; # Adjust as needed
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nixos = import ./home.nix;
  };

  # Nix configuration optimized for WSL
  nix = {
    settings = {
      # Enable flakes
      experimental-features = [ "nix-command" "flakes" ];
      
      # Optimize for WSL storage
      auto-optimise-store = true;
      
      # Build settings optimized for Windows host
      max-jobs = "auto";
      cores = 0;
      
      # Trusted users
      trusted-users = [ "root" "nixos" ];
      
      # Substituters
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  # Allow unfree packages for development tools
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = "25.05";
}