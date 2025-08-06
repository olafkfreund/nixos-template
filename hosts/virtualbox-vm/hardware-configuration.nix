# VirtualBox VM Hardware Configuration Template
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/profiles/qemu-guest.nix")
    ];

  # Boot loader configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    timeout = 5;
  };

  # Kernel modules for VirtualBox
  boot.initrd.availableKernelModules = [ 
    "ata_piix" 
    "ohci_pci" 
    "ehci_pci" 
    "ahci" 
    "sd_mod" 
    "sr_mod" 
  ];
  
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "vboxguest" "vboxsf" "vboxvideo" ];
  boot.extraModulePackages = [ ];

  # File systems - typical VirtualBox setup
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = lib.mkIf (config.boot.loader.grub.device == "nodev") {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    fsType = "vfat";
  };

  # Swap configuration
  swapDevices = [
    { device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-SWAP-UUID"; }
  ];

  # Network interfaces
  networking.interfaces = {
    enp0s3.useDHCP = lib.mkDefault true;
    enp0s8.useDHCP = lib.mkDefault true;  # Host-only adapter
  };

  # CPU and hardware configuration
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # VirtualBox-specific hardware
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Audio configuration
  hardware.pulseaudio = {
    enable = lib.mkDefault true;
    support32Bit = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
}