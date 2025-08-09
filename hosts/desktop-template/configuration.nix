# Desktop Configuration Template - Simplified
# Uses the profile system instead of duplicating packages
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
    ../../modules/profiles/workstation.nix # Contains all the packages and common configs
  ];

  # System identification
  systemId = {
    baseName = "desktop-template";
    profile = "workstation";
    description = "Desktop template for workstation environments";
    environment = "development";
    tags = [ "template" "desktop" ];
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
    debug = true;
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
      allowedTCPPorts = [ 22 80 443 8080 ];
    };
    interfaces.enp0s31f6.wakeOnLan.enable = true;
  };

  # Services - only host-specific configurations
  services = {
    pulseaudio.enable = false; # Using PipeWire from desktop module
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = lib.mkForce true;
      };
    };
    displayManager.autoLogin.enable = false;
    ntp.enable = true;
  };

  # Use latest kernel for best hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Home Manager integration - simplified
  home-manager.users.user = import ./home.nix;

  # System maintenance
  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = false;
      dates = "weekly";
    };
    stateVersion = "25.05";
  };
}
