# Workstation Profile Module
# Contains all packages and configurations for a high-performance desktop workstation
{ config, lib, pkgs, ... }:

{
  # Hardware configuration for desktop workstation
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
          Experimental = true;
        };
      };
    };
  };

  # Sound with PipeWire (professional audio support)
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
        default = {
          clock = {
            rate = 48000;
            quantum = 32;
            min-quantum = 32;
            max-quantum = 32;
          };
        };
      };
    };
  };

  # Kernel configuration for desktop performance
  boot = {
    kernelModules = [ "kvm-intel" "kvm-amd" ];

    kernelParams = [
      # Enable full CPU performance
      "intel_pstate=active"
      "amd_pstate=active"
      # Optimize for desktop responsiveness
      "preempt=voluntary"
      # Enable all CPU features
      "mitigations=auto"
    ];

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

  # Enable hibernation support
  boot.resumeDevice = "/dev/disk/by-label/nixos";

  # Large tmpfs for better performance
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "50%"; # Use half of RAM for /tmp
  };

  # Services for workstation
  services = {
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

    # Flatpak for additional software
    flatpak.enable = true;
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

    # Workstation packages - centralized here to eliminate duplication
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

  # User configuration for workstation
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
              options = [ "SETENV" ];
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
}
