{ lib, pkgs, ... }:

{
  imports = [
    # Hardware configuration (generate with nixos-generate-config)
    ./hardware-configuration.nix

    # Common configuration
    ../common.nix

    # Core modules
    ../../modules/core

    # Development tools (optional)
    ../../modules/development

    # Desktop environment
    ../../modules/desktop/gnome.nix
  ];

  # Hostname
  networking.hostName = "desktop-test";

  # Minimal VM guest configuration (disable complex vm-guest module)
  # modules.virtualization.vm-guest = {
  #   enable = true;
  #   type = "qemu";
  # };

  # Manual VM guest settings for maximum reliability
  services.qemuGuest.enable = true;

  # Desktop configuration
  modules.desktop.gnome.enable = true;

  # VM-specific systemd service overrides to prevent boot hangs
  systemd.services = {
    # Disable problematic services in VMs
    "systemd-hwdb-update".enable = false;
    "systemd-journal-flush".enable = false;

    # Disable growpart service (causes failures in VMs)
    "growpart".enable = false;

    # Disable logrotate service (causes configuration check failures in VMs)
    "logrotate".enable = false;
    "logrotate-checkconf".enable = false;

    # Mask cloud-init related services that cause VM issues
    "cloud-config".enable = false;
    "cloud-final".enable = false;
    "cloud-init".enable = false;
    "cloud-init-local".enable = false;

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

    # Disable problematic services for VMs
    logrotate.enable = lib.mkForce false;
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
    # Additional network tools
    socat

    # Development conveniences
    git
    curl
    wget

    # VM-specific utilities
    pciutils # lspci for hardware debugging
    usbutils # lsusb for USB debugging
  ];

  # Boot configuration for reliable VM startup
  boot = {
    # Disable partition growing in VMs (causes service failures)
    growPartition = lib.mkForce false;

    # Kernel parameters for VM stability
    kernelParams = [
      "quiet" # Reduce boot messages
      "systemd.unit=graphical.target" # Boot directly to graphical target
      "systemd.mask=growpart.service" # Mask growpart service
      "systemd.mask=logrotate.service" # Mask logrotate service
      "systemd.mask=logrotate-checkconf.service" # Mask logrotate check
      "systemd.mask=systemd-hwdb-update.service" # Mask hwdb update
      "systemd.mask=systemd-journal-flush.service" # Mask journal flush
      "kvm.ignore_msrs=1" # Ignore missing MSRs in nested virtualization
    ];

    # Disable kernel modules that cause issues in VMs
    blacklistedKernelModules = [
      "kvm_intel" # Prevents VMX errors in nested virtualization
      "kvm_amd" # Prevents SVM errors in nested virtualization
    ];

    # Timeout settings
    loader.timeout = lib.mkForce 1;
  };

  # System state version
  system.stateVersion = "25.05";
}
