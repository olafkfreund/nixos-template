# Hardware Configuration Template
# Generate your actual hardware config with: sudo nixos-generate-config
{ config, lib, ... }: {
  # Replace with your actual hardware modules
  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-intel" ]; # Change to kvm-amd for AMD
  };

  # Replace UUIDs with your actual values
  fileSystems = {
    "/" = { device = "/dev/disk/by-uuid/REPLACE-ROOT-UUID"; fsType = "ext4"; };
    "/boot" = { device = "/dev/disk/by-uuid/REPLACE-BOOT-UUID"; fsType = "vfat"; };
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/REPLACE-SWAP-UUID"; }];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
