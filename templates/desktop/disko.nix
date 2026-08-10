# Disk layout: UEFI + LUKS2 full-disk encryption + btrfs subvolumes.
#
# Declaring the layout here rather than running `cryptsetup` by hand is what
# makes the boot-time passphrase prompt appear. The usual failure -- install
# finishes, reboot hangs on a mount timeout, never asks for the passphrase --
# is a hand-made LUKS partition that nothing ever declared to the initrd.
#
# ⚠ disko ERASES the device below. Check it first:
#
#     lsblk -o NAME,SIZE,MODEL
#
# Then install with:
#
#     sudo nix --experimental-features "nix-command flakes" run \
#       github:nix-community/disko/latest -- --mode destroy,format,mount ./disko.nix
#     sudo nixos-install --flake .#my-desktop
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1"; # ← CHANGE ME
    content = {
      type = "gpt";
      partitions = {
        # Unencrypted by necessity: the firmware has to read it.
        ESP = {
          size = "1G"; # 512M runs out after a few generations
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
            settings.allowDiscards = true; # SSD TRIM; leaks used-space metadata
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
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
                # /nix is already compressed and is the hottest read path.
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "noatime" ];
                };
                # Btrfs cannot snapshot an active swapfile, so it lives alone.
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
}
