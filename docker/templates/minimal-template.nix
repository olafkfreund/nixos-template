# Minimal Template for VM Builder
# Lightweight NixOS installation with essential tools only
{ config, pkgs, lib, ... }:

{
  imports = [
    # Enable VM optimizations
    <nixpkgs/nixos/modules/virtualisation/virtualbox-guest.nix>
    <nixpkgs/nixos/modules/virtualisation/qemu-guest-agent.nix>
  ];

  # System configuration
  system.stateVersion = "24.05";

  # Boot configuration for VMs
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Minimal kernel configuration
  boot.kernelParams = [
    "elevator=noop"
    "quiet"
    "console=tty0"
    "console=ttyS0,115200"
  ];

  # Minimal essential packages only
  environment.systemPackages = with pkgs; [
    # Core system tools
    git
    curl
    wget
    vim
    nano
    htop

    # Basic utilities
    tree
    unzip
    file
    which

    # Network basics
    netcat

    # VM integration (minimal)
    spice-vdagent
  ];

  # No desktop environment - minimal CLI only
  services.xserver.enable = false;

  # Basic SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
    ports = [ 22 ];
  };

  # Minimal networking
  networking = {
    hostName = "nixos-minimal";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # Single user setup
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS Minimal User";
    extraGroups = [ "networkmanager" "wheel" ];
    password = "nixos"; # Change this in production
  };

  # Secure sudo (require password)
  security.sudo.wheelNeedsPassword = true;

  # Essential VM guest services only
  services = {
    qemuGuest.enable = true;
    spice-vdagentd.enable = true;
  };

  # Disable unnecessary services for minimal footprint
  services = {
    # System services
    smartd.enable = false;
    udisks2.enable = false;

    # Network services
    avahi.enable = false;
    printing.enable = false;

    # Desktop services
    flatpak.enable = false;
  };

  # Minimal power management
  powerManagement.enable = false;

  # VM-specific optimizations for minimal resource usage
  virtualisation = {
    diskSize = lib.mkDefault 10240; # 10GB minimal
    memorySize = lib.mkDefault 1024; # 1GB RAM
    cores = lib.mkDefault 1;

    # Minimal graphics
    qemu.options = [
      "-vga cirrus"
      "-display none"
    ];
  };

  # Minimal system optimizations
  boot.kernel.sysctl = {
    # Conservative memory settings
    "vm.swappiness" = 60; # Default swapping
    "vm.vfs_cache_pressure" = 100; # Default cache pressure
  };

  # Enable flakes with conservative settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Conservative build settings for minimal resources
    max-jobs = 1;
    cores = 1;
    # Use binary cache to avoid compilation
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Aggressive garbage collection for space savings
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Minimal locale settings
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Disable documentation to save space
  documentation = {
    enable = false;
    nixos.enable = false;
    man.enable = false;
    info.enable = false;
    doc.enable = false;
  };

  # Minimal time zone
  time.timeZone = "UTC";

  # No fonts package (CLI only)
  fonts.fontconfig.enable = false;
}
