# Desktop Configuration Template
# Optimized for high-performance desktop computing
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/power-management.nix
    ../../modules/gaming
    ../../modules/development
  ];

  # System identification
  networking.hostName = "desktop-template";

  # Hardware profile for desktop
  modules.hardware.power-management = {
    enable = true;
    profile = "desktop";
    cpuGovernor = "ondemand"; # Balance between performance and power
    enableThermalManagement = true;

    desktop = {
      enablePerformanceMode = true;
      disableUsbAutosuspend = true; # Better for gaming peripherals
    };
  };

  # Full-featured desktop environment
  modules.desktop = {
    audio.enable = true;

    gnome = {
      enable = true;
      # Keep all applications for full desktop experience
    };
  };

  # Disable PulseAudio in favor of PipeWire (handled by modules.desktop.audio)
  services.pulseaudio.enable = false;

  # Gaming support
  modules.gaming = {
    steam = {
      enable = true;
      performance.gamemode = true;
      performance.mangohud = true;
    };
  };

  # Development tools
  modules.development = {
    git = {
      enable = true;
      userName = "Desktop User";
      userEmail = "user@example.com";
    };
  };

  # Network configuration
  networking = {
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        80 # HTTP
        443 # HTTPS
        8080 # Development servers
      ];
      allowedUDPPorts = [
        # Add any UDP ports you need
      ];
    };

    # Enable Wake-on-LAN for remote access
    interfaces.enp0s31f6.wakeOnLan.enable = true;
  };

  # Services optimized for desktop use
  services = {
    # OpenSSH for remote access
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = lib.mkForce true; # Enable for desktop development
      };
    };

    # Auto-login for convenience (disable if shared computer)
    displayManager.autoLogin = {
      enable = false; # Set to true if desired
      user = "user";
    };

    # Hardware sensors monitoring
    # Hardware monitoring
    # lm_sensors.enable = true;  # This service doesn't exist, enable via hardware

    # Automatic time sync
    ntp.enable = true;

    # Flatpak for additional software
    flatpak.enable = true;

    # Printing and scanning
    printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        gutenprintBin
        hplip
        epson-escpr
        canon-cups-ufr2
      ];
    };

    # CUPS for printer discovery
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Samba for file sharing
    samba = {
      enable = true;
      openFirewall = true;
    };
  };

  # Hardware configuration for desktop
  hardware = {
    # Full graphics acceleration
    graphics = {
      enable = true;
      enable32Bit = true; # For games and legacy applications

      extraPackages = with pkgs; [
        mesa
        libvdpau-va-gl
        vaapiVdpau
      ];
    };

    # Audio with all features (pulseaudio is configured via services.pulseaudio)
    # pulseaudio.enable moved to services.pulseaudio in modules

    # Enable all CPU microcode updates
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Bluetooth with full feature set
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true; # Enable experimental features
        };
      };
    };
  };

  # Sound with PipeWire (professional audio support)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true; # Professional audio
    wireplumber.enable = true;

    # Low-latency configuration for audio work
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 32;
        default.clock.min-quantum = 32;
        default.clock.max-quantum = 32;
      };
    };
  };

  # Kernel configuration for desktop performance
  boot = {
    kernelModules = [
      "kvm-intel"
      "kvm-amd"
    ];

    kernelParams = [
      # Enable full CPU performance
      "intel_pstate=active"
      "amd_pstate=active"

      # Optimize for desktop responsiveness
      "preempt=voluntary"

      # Enable all CPU features
      "mitigations=auto"
    ];

    # Use latest kernel for best hardware support
    kernelPackages = pkgs.linuxPackages_latest;

    # Plymouth for smooth boot
    plymouth = {
      enable = true;
      theme = "breeze";
    };

    # Faster boot
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };

  # Desktop-optimized file systems
  fileSystems."/" = {
    options = [
      "noatime"
      "discard" # SSD TRIM support
    ];
  };

  # Swap configuration for desktop (hibernation support)
  swapDevices = [ ];

  # Enable hibernation support
  boot.resumeDevice = "/dev/disk/by-label/nixos";

  # Large tmpfs for better performance
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%"; # Use half of RAM for /tmp
  };

  # Environment optimized for desktop productivity
  environment = {
    variables = {
      # Hardware acceleration
      VDPAU_DRIVER = lib.mkIf config.hardware.graphics.enable "va_gl";
      LIBVA_DRIVER_NAME = "iHD";

      # Qt/GTK scaling
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      GDK_SCALE = "1";

      # Development
      EDITOR = "code";
      BROWSER = "firefox";

      # Gaming
      DXVK_HUD = "compiler";
      RADV_PERFTEST = "gpl";
    };

    systemPackages = with pkgs; [
      # Desktop applications
      firefox
      chromium
      thunderbird
      libreoffice
      gimp
      inkscape
      blender
      obs-studio
      vlc

      # Development tools
      vscode
      jetbrains.idea-community
      docker-compose
      postman

      # System utilities
      htop
      iotop
      nethogs
      lm_sensors
      smartmontools
      gparted

      # Gaming utilities
      lutris
      heroic
      discord

      # Multimedia
      audacity
      handbrake
      kdePackages.kdenlive

      # Network tools
      wireshark
      nmap
      tcpdump

      # Archive tools
      p7zip
      unrar

      # Backup and sync
      rsync
      rclone
      borgbackup
    ];
  };

  # Virtualization support
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };

    # Docker for development
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
  };

  # User configuration
  users.users.user = {
    isNormalUser = true;
    description = "Desktop User";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "docker"
      "libvirtd"
      "plugdev" # For hardware access
    ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
    ];
  };

  # Security configuration
  security = {
    sudo = {
      enable = true;
      extraRules = [
        {
          users = [ "user" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ]; # Remove this for better security
            }
          ];
        }
      ];
    };

    # Enable PAM
    pam.services.login.enableGnomeKeyring = true;

    # Polkit for GUI privilege escalation
    polkit.enable = true;
  };

  # XDG portals for sandboxed applications
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  # Fonts for desktop use
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      source-code-pro
      ubuntu_font_family

      # Microsoft fonts for compatibility
      corefonts
      vistafonts
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "JetBrains Mono" ];
      };
    };
  };

  # Home Manager integration
  home-manager.users.user = import ./home.nix;

  # System maintenance
  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = false; # Don't auto-reboot desktop
      dates = "weekly";
    };

    stateVersion = "25.05";
  };
}
