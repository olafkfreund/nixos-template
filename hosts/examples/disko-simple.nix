# Disko layout: UEFI + ext4, no encryption.
#
# The plainest thing that works, and the right starting point if you are not
# sure you need anything else. One EFI system partition, one root filesystem,
# swap as a file rather than a partition so resizing is a one-line change.
#
# Usage -- in your host's configuration.nix:
#
#   imports = [
#     inputs.disko.nixosModules.disko
#     ../examples/disko-simple.nix
#   ];
#
# Then set the device. ALWAYS check this first, disko will erase it:
#
#   lsblk -o NAME,SIZE,MODEL          # /dev/sda? /dev/nvme0n1? /dev/vda?
#
# See docs/DISK-SETUP.md for the full install walkthrough.
{ lib, ... }:

{
  # Overridable per host: `disko.devices.disk.main.device = "/dev/sda";`
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          # 1G, not the 512M you will see in older guides. Kernels and
          # initrds have grown; 512M runs out after a handful of
          # generations and the failure looks like a broken rebuild.
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ]; # keys and initrds live here
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };

  # Swap as a file. Grow or shrink it by editing one number and rebuilding;
  # a swap partition would mean repartitioning. Size it >= RAM only if you
  # want hibernation to work.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024; # MiB
    }
  ];
}
