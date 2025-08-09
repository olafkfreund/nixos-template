{ lib, pkgs, ... }:

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
  ];

  # Hostname
  networking.hostName = "qemu-vm";

  # Enable VM guest optimizations
  modules.virtualization.vm-guest = {
    enable = true;
    type = "qemu"; # Can also use "auto" for auto-detection

    optimizations = {
      performance = true;
      graphics = true;
      networking = true;
      storage = true;
    };

    guestTools = {
      enable = true;
      clipboard = true;
      folderSharing = true;
      timeSync = true;
    };

    serial = {
      enable = true;
    };
  };

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

  # Additional virtualization settings
  boot = {
    # Resize root partition on boot (useful for cloud images)
    growPartition = true;
  };

  # System state version
  system.stateVersion = "25.05";
}
