# Laptop Configuration Template
# Optimized for mobile computing with battery life and portability
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/power-management.nix
  ];

  # System identification
  networking.hostName = "laptop-template";

  # Hardware profile
  modules.hardware.power-management = {
    enable = true;
    profile = "laptop";
    enableThermalManagement = true;

    laptop = {
      enableBatteryOptimization = true;
      enableTlp = true;
      suspendMethod = "suspend";
      wakeOnLid = true;
    };
  };

  # Desktop environment optimized for laptop use
  modules.desktop = {
    audio.enable = true;
    gnome.enable = true;
  };

  # Printing support (often needed for mobile work)
  services.printing.enable = true;

  # Network configuration for mobile use
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        powersave = true; # Enable WiFi power saving
        backend = "iwd"; # Modern WiFi backend
      };
    };

    # VPN support for secure remote work
    firewall = {
      enable = true;
      allowPing = false; # More secure for mobile use
    };
  };

  # Services optimized for laptops
  services = {
    # Disable power-profiles-daemon when TLP is used
    power-profiles-daemon.enable = lib.mkForce false;

    # Automatic time synchronization (important for mobile devices)
    timesyncd.enable = true;

    # Location services for automatic timezone
    geoclue2.enable = true;

    # Automatic brightness adjustment
    clight = {
      enable = true;
      settings = {
        verbose = true;
        backlight.disabled = false;
        dpms.timeouts = [ 600 1200 ]; # Screen timeout on battery
        screen.contrib = 0.1;
        keyboard.disabled = true;
      };
    };

    # Fingerprint authentication (if available)
    fprintd.enable = true;

    # Suspend on low battery
    logind = {
      powerKey = "suspend";
      lidSwitch = "suspend";
      lidSwitchExternalPower = "ignore";
    };
  };

  # Hardware-specific optimizations
  hardware = {
    # Graphics with power management
    graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Audio power management (moved to services)
    # pulseaudio.enable = false;  # Use PipeWire instead

    # Bluetooth low energy support
    bluetooth = {
      enable = true;
      powerOnBoot = false; # Don't auto-start to save power
    };
  };

  # Sound with PipeWire (better power management than PulseAudio)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # Kernel modules for laptop hardware
  boot = {
    kernelModules = [
      "acpi_call" # For battery threshold control
    ];

    extraModulePackages = with config.boot.kernelPackages; [
      acpi_call
    ];

    kernelParams = [
      # Intel graphics power saving
      "i915.enable_psr=1"
      "i915.enable_fbc=1"
      "i915.fastboot=1"

      # ACPI support
      "acpi_backlight=native"

      # Reduce boot time
      "quiet"
      "splash"
    ];
  };

  # Laptop-friendly file systems
  fileSystems."/" = {
    options = [
      "noatime" # Reduce SSD wear and improve battery life
      "nodiratime"
      "discard" # Enable TRIM for SSD
    ];
  };

  # Swap configuration
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; # Use half of RAM for compressed swap
  };

  # Environment variables for laptop use
  environment = {
    variables = {
      # Enable hardware video acceleration
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "iHD"; # Intel hardware acceleration

      # Qt scaling for high DPI screens
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_ENABLE_HIGHDPI_SCALING = "1";

      # GTK scaling
      GDK_SCALE = "1";
      GDK_DPI_SCALE = "1";
    };

    systemPackages = with pkgs; [
      # Laptop-specific utilities
      brightnessctl # Backlight control
      acpi # Battery information
      powertop # Power usage monitoring
      tlp # Advanced power management
      upower # Battery status

      # Mobile work essentials
      networkmanager # Network management
      networkmanagerapplet
      blueman # Bluetooth manager

      # Document scanning (common laptop use case)
      simple-scan

      # VPN clients
      openvpn
      wireguard-tools

      # Laptop maintenance
      smartmontools # Disk health monitoring

      # Screen management
      autorandr # Automatic display configuration
    ];
  };

  # Security enhancements for mobile devices
  security = {
    # Protect against physical access
    pam.services.login.enableGnomeKeyring = true;

    # Enable sudo with timeout
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults timestamp_timeout=15
      '';
    };
  };

  # Fonts optimized for laptop screens
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      # High-quality fonts for laptop screens
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Fira Code" ];
      };
    };
  };

  # User configuration
  users.users.user = {
    isNormalUser = true;
    description = "Laptop User";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "plugdev"
    ];
    group = "users";
  };

  # Home Manager integration
  home-manager.users.user = import ./home.nix;

  # Enable periodic maintenance
  system = {
    autoUpgrade = {
      enable = false; # Don't auto-upgrade on laptops to preserve battery
    };

    stateVersion = "25.05";
  };
}
