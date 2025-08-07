# WSL2 Hardware Configuration
# This is a minimal hardware configuration for WSL2 environment

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];

  # WSL2 doesn't use traditional bootloaders
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # WSL2 filesystem configuration
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  # No swap in WSL2 by default (Windows manages memory)
  swapDevices = [ ];

  # Network configuration handled by WSL2
  networking.useDHCP = lib.mkDefault true;

  # Hardware detection
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # WSL2-specific hardware settings
  hardware = {
    # No real hardware in WSL2
    enableAllFirmware = false;
    enableRedistributableFirmware = false;

    # Graphics handled by Windows
    graphics = {
      enable = true;
      enable32Bit = false; # Usually not needed in WSL2
    };

    # Audio through PulseAudio
    pulseaudio.enable = true;

    # No Bluetooth in WSL2
    bluetooth.enable = false;
  };

  # Virtualization settings for nested containers
  virtualisation = {
    # Docker/Podman support
    docker.enable = false; # Can be enabled per-host
    podman.enable = false; # Can be enabled per-host
  };

  # Power management not applicable in WSL2
  powerManagement.enable = false;
  services.thermald.enable = false;
  services.auto-cpufreq.enable = false;

  # Location services not available
  services.geoclue2.enable = false;

  # No real time clock in WSL2
  services.timesyncd.enable = true;
}
