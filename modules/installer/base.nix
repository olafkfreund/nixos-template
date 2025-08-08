# Base installer configuration
# This module provides common settings for all installer ISOs

{ lib, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
  ];

  # ISO Label and metadata
  image = {
    fileName = lib.mkDefault "nixos-installer.iso";
  };
  isoImage = {
    volumeID = lib.mkDefault "NIXOS_INSTALLER";

    # Modern boot methods
    makeEfiBootable = true;
    makeUsbBootable = true;

    # Compression for smaller ISOs
    squashfsCompression = "gzip -Xcompression-level 1";
  };

  # Enable SSH for remote installation
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Set root password for installer (change this!)
  # Override the default locked password from core/users.nix for installer environments
  users.users.root = {
    # Use initialPassword for installer - this overrides hashedPassword with higher precedence
    initialPassword = lib.mkOverride 50 "nixos"; # Lower number = higher priority than mkDefault (1000)
    # Aggressively clear ALL other password options to prevent conflicts
    hashedPassword = lib.mkOverride 60 null;
    password = lib.mkOverride 60 null;
    # Force initialHashedPassword to null to override any system defaults
    initialHashedPassword = lib.mkOverride 60 null;
    hashedPasswordFile = lib.mkOverride 60 null;
  };

  # Essential packages for installation
  environment.systemPackages = with pkgs; [
    # Text editors
    nano
    vim

    # Network tools
    wget
    curl
    git

    # Disk utilities
    gptfdisk
    parted

    # System utilities
    htop
    tree
    lsof

    # Hardware detection
    pciutils
    usbutils
    lshw

    # Development tools (for custom configs)
    just
    nixpkgs-fmt
  ];

  # Network configuration
  networking = {
    wireless.enable = lib.mkForce false; # Disable wpa_supplicant
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
  };

  # Enable firmware for hardware compatibility
  hardware.enableRedistributableFirmware = true;

  # Enable flakes in installer
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" ];
    };

    # Include this configuration in the installer
    nixPath = [
      "nixpkgs=${pkgs.path}"
      "nixos-config=/etc/nixos/configuration.nix"
    ];
  };

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  # Locale settings
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  time.timeZone = lib.mkDefault "UTC";

  # System version (will be set by specific ISO configs)
  system.stateVersion = "25.05";
}
