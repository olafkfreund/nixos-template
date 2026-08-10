# Desktop Configuration Template - Simplified
# Uses the profile system instead of duplicating packages
{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/core
    ../../modules/desktop
    ../../modules/hardware/power-management.nix
    ../../modules/gaming
    ../../modules/development
    ../../modules/presets
  ];

  # Everything a workstation needs -- packages, services, virtualisation --
  # comes from the preset. Override any of it below.
  modules.presets = {
    enable = true;
    preset = "workstation";
  };

  # System identification
  systemId = {
    baseName = "desktop-template";
    profile = "workstation";
    description = "Desktop template for workstation environments";
    environment = "development";
    tags = [
      "template"
      "desktop"
    ];
  };

  # Module configuration
  modules = {
    # Hardware profile for desktop
    hardware.power-management = {
      enable = true;
      profile = "desktop";
      cpuGovernor = "ondemand";
      enableThermalManagement = true;

      desktop = {
        enablePerformanceMode = true;
        disableUsbAutosuspend = true;
      };
    };

    # Full-featured desktop environment
    desktop = {
      audio.enable = true;
      gnome.enable = true;
    };

    # Gaming support
    gaming = {
      steam = {
        enable = true;
        performance.gamemode = true;
        performance.mangohud = true;
      };
    };

    # Development tools
    development = {
      git = {
        enable = true;
        userName = "Desktop User";
        userEmail = "user@example.com";
      };
    };
  };

  # Zero-configuration hardware optimization
  hardware.autoOptimization = {
    enable = true;
    debug = false; # set true to have the detected hardware printed on rebuild
    detection = {
      enableMemoryOptimization = true;
      enableCpuOptimization = true;
      enableGpuOptimization = true;
      enableStorageOptimization = true;
      enablePlatformOptimization = true;
    };
  };

  # Network configuration
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # A desktop serves nothing. Open only what you actually listen on --
      # every extra port here is reachable from your whole LAN.
      allowedTCPPorts = [ 22 ]; # SSH, for `just switch` from another machine
      # Running a dev server you want to reach from your phone? Add it:
      # allowedTCPPorts = [ 22 3000 ];
    };
    # No `interfaces.<name>` block: interface names differ on every machine
    # (enp0s31f6, eno1, wlp3s0...). NetworkManager handles whatever you have.
    # Wake-on-LAN, if you want it, needs YOUR interface name from `ip link`:
    # interfaces.eno1.wakeOnLan.enable = true;
  };

  # Services - only host-specific configurations
  services = {
    pulseaudio.enable = false; # Using PipeWire from desktop module
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    displayManager.autoLogin.enable = false;
    ntp.enable = true;
  };

  # Use latest kernel for best hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Home Manager integration - simplified
  # Defined here rather than inherited from a shared module, matching
  # laptop-template and server-template.
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
      "plugdev"
    ];
    group = "users";
  };

  home-manager.users.user = import ./home.nix;

  # System maintenance
  system = {
    # Off by default. Unattended upgrades on a machine you are still learning
    # to configure means waking up to a changed system you did not change --
    # run `just update && just switch <host>` when you are ready instead.
    autoUpgrade = {
      enable = false;
      allowReboot = false;
      dates = "weekly";
    };
    stateVersion = "26.05";
  };
}
