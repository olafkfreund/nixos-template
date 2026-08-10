# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  PLACEHOLDER -- REPLACE THIS FILE BEFORE YOU BUILD                        ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# This stub exists so the template evaluates immediately after
# `nix flake init`. It describes no real machine and will not boot one.
#
# Generate the real thing on the target machine:
#
#   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# That detects your actual disks, filesystem UUIDs, and kernel modules. It is
# the one file in a NixOS config that is genuinely per-machine, which is why
# it is also the one file you should never copy from someone else's repo.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  boot.loader.grub.device = lib.mkDefault "nodev";

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
