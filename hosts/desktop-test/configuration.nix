{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    # Hardware configuration (generate with nixos-generate-config)
    ./hardware-configuration.nix

    # Common configuration
    ../common.nix

    # VM guest optimizations
    ../../modules/virtualization/vm-guest.nix

    # Core modules  
    ../../modules/core

    # Development tools (optional)
    ../../modules/development

    # Desktop environment
    ../../modules/desktop/gnome.nix
  ];

  # Hostname
  networking.hostName = "desktop-test";

  # Enable VM guest optimizations (simplified to prevent boot issues)
  modules.virtualization.vm-guest = {
    enable = true;
    type = "qemu";

    optimizations = {
      performance = false; # Disable to prevent systemd conflicts
      graphics = true;
      networking = true;
      storage = false; # Disable to prevent boot hangs
    };

    guestTools = {
      enable = true;
      clipboard = true;
      folderSharing = false; # Disable to prevent mount issues
      timeSync = true;
    };

    serial = {
      enable = false; # Disable to prevent boot hangs
    };
  };

  # Desktop configuration
  modules.desktop.gnome.enable = true;
  
  # VM-specific systemd service overrides to prevent boot hangs
  systemd.services = {
    # Disable problematic services in VMs
    "systemd-hwdb-update".enable = false;
    "systemd-journal-flush".enable = false;
    
    # Ensure critical services start properly
    "systemd-logind".serviceConfig = {
      Restart = "always";
      RestartSec = 1;
    };
  };
  
  # Disable AppArmor in VMs (can cause boot issues)
  security.apparmor.enable = lib.mkForce false;
  
  # Users
  users.users.vm-user = {
    isNormalUser = true;
    description = "VM User";
    extraGroups = [ "wheel" "networkmanager" ];

    # Set initial password (change after first login)
    initialPassword = "nixos";
  };

  # Allow wheel group to sudo without password (VM convenience)
  security.sudo.wheelNeedsPassword = false;

  # Home Manager configuration for the user
  home-manager.users.vm-user = import ./home.nix;

  # VM-specific services (additional to what vm-guest module provides)
  services = {
    # Enable SSH for remote access
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true; # Allow for initial setup
        PermitRootLogin = "no";
      };
    };
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH
    allowPing = true;
  };

  # Development tools (optional, can be disabled for minimal VMs)
  modules.development.git = {
    enable = lib.mkDefault true;
    userName = lib.mkDefault "VM User";
    userEmail = lib.mkDefault "vm-user@example.com";
  };

  # Additional system packages beyond what vm-guest provides
  environment.systemPackages = with pkgs; [
    # Cloud utilities for VM deployment
    cloud-utils

    # Additional network tools
    socat

    # Development conveniences
    git
    curl
    wget
  ];

  # Boot configuration for reliable VM startup
  boot = {
    # Resize root partition on boot (useful for cloud images)
    growPartition = true;
    
    # Kernel parameters for VM stability
    kernelParams = [
      "quiet"           # Reduce boot messages
      "systemd.unit=graphical.target"  # Boot directly to graphical target
    ];
    
    # Timeout settings
    loader.timeout = lib.mkForce 1;
  };

  # System state version
  system.stateVersion = "25.05";
}
