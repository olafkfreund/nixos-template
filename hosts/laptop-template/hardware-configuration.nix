# Hardware Configuration Template
# Generate your actual hardware config with: sudo nixos-generate-config
{ config, lib, ... }: {
  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
    kernelModules = [ "kvm-intel" ]; # Change to kvm-amd for AMD
  };

  fileSystems = {
    "/" = { device = "/dev/disk/by-uuid/REPLACE-ROOT-UUID"; fsType = "ext4"; };
    "/boot" = { device = "/dev/disk/by-uuid/REPLACE-BOOT-UUID"; fsType = "vfat"; };
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/REPLACE-SWAP-UUID"; }];

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
