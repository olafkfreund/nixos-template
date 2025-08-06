# Server Template Hardware Configuration
# This is a placeholder - replace with your actual hardware configuration
# Generate with: sudo nixos-generate-config

{ config, lib, ... }:

{
  imports = [ ];

  # This is a template file - you MUST replace these with your actual hardware details
  # Generate the real configuration with: sudo nixos-generate-config

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # Change to "kvm-amd" for AMD
  boot.extraModulePackages = [ ];

  # PLACEHOLDER - Replace these UUIDs with your actual device UUIDs
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-ROOT-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-BOOT-UUID";
    fsType = "vfat";
  };

  # No swap for servers typically, but add if needed
  swapDevices = [ ];

  # Enables DHCP on each ethernet interface
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
