# Disko layout: UEFI + LUKS2 full-disk encryption + btrfs subvolumes.
#
# This is the layout the graphical installer cannot give you, and hand-rolling
# it is where new installs most often die: people run `cryptsetup luksFormat`
# by hand, install, reboot, and are never prompted for the passphrase -- the
# boot just hangs on a mount timeout, because nothing ever declared
# `boot.initrd.luks.devices`.
#
# Declaring the layout here generates that initrd entry for you, so the
# passphrase prompt exists because the partition exists. They cannot drift.
#
# Usage -- in your host's configuration.nix:
#
#   imports = [
#     inputs.disko.nixosModules.disko
#     ../examples/disko-luks-btrfs.nix
#   ];
#
# Check the device before you run anything. disko will erase it:
#
#   lsblk -o NAME,SIZE,MODEL
#
# See docs/DISK-SETUP.md for the full install walkthrough.
{ lib, ... }:

{
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        # The ESP cannot be encrypted -- the firmware has to read it.
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";

            # Prompts on boot. To use a keyfile on a USB stick instead, see
            # `settings.keyFile` in the disko docs -- do not put a passphrase
            # in this file, it would land world-readable in the Nix store.
            settings.allowDiscards = true; # SSD TRIM; slight metadata leak

            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];

              # Subvolumes, not partitions: they share one pool, so none of
              # them can fill up while another sits half empty.
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                # No compression on /nix: the store is already compressed,
                # and it is the hottest read path on the system.
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "noatime" ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                # Btrfs cannot snapshot an active swapfile, so it gets its
                # own nodatacow subvolume.
                "@swap" = {
                  mountpoint = "/swap";
                  swap.swapfile.size = "8G";
                };
              };
            };
          };
        };
      };
    };
  };

  # /boot is unencrypted by necessity, so an attacker with physical access can
  # tamper with the kernel there. Secure Boot with your own keys (lanzaboote)
  # closes that gap; full-disk encryption alone does not.
  fileSystems."/persist".neededForBoot = true;
}
