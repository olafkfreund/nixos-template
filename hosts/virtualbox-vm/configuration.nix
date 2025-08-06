{ config, lib, pkgs, ... }:

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

    # Desktop environment (optional)
    ../../modules/desktop
  ];

  # Hostname
  networking.hostName = "virtualbox-vm";

  # Enable VirtualBox VM guest optimizations
  modules.virtualization.vm-guest = {
    enable = true;
    type = "virtualbox";

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
      enable = false; # VirtualBox usually doesn't need serial console
    };
  };

  # Users
  users.users.vbox-user = {
    isNormalUser = true;
    description = "VirtualBox VM User";
    extraGroups = [ "wheel" "networkmanager" "vboxsf" ];

    # Set initial password (change after first login)
    initialPassword = "nixos";
  };

  # Allow wheel group to sudo without password (VM convenience)
  security.sudo.wheelNeedsPassword = false;

  # Home Manager configuration for the user
  home-manager.users.vbox-user = import ./home.nix;

  # VirtualBox-specific services
  services = {
    # Enable SSH for remote access (optional)
    openssh = {
      enable = lib.mkDefault false; # Usually not needed in desktop VMs
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    # X11 and desktop services
    xserver = {
      enable = lib.mkDefault true;
      displayManager.lightdm.enable = lib.mkDefault true;
      desktopManager.xfce.enable = lib.mkDefault true; # Lightweight for VMs
    };
  };

  # VirtualBox-specific configurations
  virtualisation.virtualbox.guest = {
    enable = true;
    x11 = true; # Enable X11 integration
  };

  # Additional packages for VirtualBox VMs
  environment.systemPackages = with pkgs; [
    # VirtualBox guest additions
    virtualboxGuestAdditions

    # File sharing utilities
    cifs-utils

    # Desktop conveniences
    firefox
    xfce.thunar
    xfce.xfce4-terminal
  ];

  # Enable desktop environment
  modules.desktop = {
    enable = lib.mkDefault true;
    environment = lib.mkDefault "xfce"; # Lightweight for VMs

    audio.enable = true;
    printing.enable = false; # Usually not needed in VMs
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowPing = true;
    # SSH port if enabled
    allowedTCPPorts = lib.optionals config.services.openssh.enable [ 22 ];
  };

  # System state version
  system.stateVersion = "25.05";
}
