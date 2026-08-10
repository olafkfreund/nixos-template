# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  PLACEHOLDER -- REPLACE THIS FILE BEFORE YOU BUILD                        ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Generate the real thing on the target machine:
#
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# Then DELETE the `fileSystems` and `swapDevices` blocks it writes. In this
# template disko.nix owns the disk layout, and two modules both defining
# `fileSystems."/"` is an evaluation conflict, not a merge. Keep the
# `boot.initrd.availableKernelModules` and `hardware.cpu.*` lines -- those are
# the parts disko knows nothing about.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "nvme"
    "xhci_pci"
    "usbhid"
    "sd_mod"
  ];

  # Uncomment the one that matches your CPU for microcode updates:
  # hardware.cpu.intel.updateMicrocode = true;
  # hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
