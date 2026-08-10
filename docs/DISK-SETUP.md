# Disk Setup with disko

Declarative partitioning. The disk layout lives in your flake next to
everything else, instead of in whatever you typed into `fdisk` eight months
ago and no longer remember.

## Why this exists

The graphical installer cannot express encryption, btrfs subvolumes, LVM or
ZFS. So people drop to a shell, run `cryptsetup` and `mkfs` by hand, install,
reboot — and the machine hangs on a mount timeout, never asking for the
passphrase.

That failure is not a mistake in the commands. It happens because a LUKS
partition made by hand is invisible to NixOS: nothing declared
`boot.initrd.luks.devices`, so the initrd has no reason to unlock anything.
Two sources of truth, and only one of them was on disk.

disko removes the second one. You declare the layout once; disko both
partitions the disk and generates the matching `fileSystems`,
`swapDevices` and `boot.initrd.luks.devices` entries. They cannot disagree,
because they are the same declaration.

## The layouts here

Two ready-to-import examples, both evaluated in CI:

| File                                                                            | Layout                                                                   |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| [`hosts/examples/disko-simple.nix`](../hosts/examples/disko-simple.nix)         | UEFI + ext4, swapfile. Start here if unsure.                             |
| [`hosts/examples/disko-luks-btrfs.nix`](../hosts/examples/disko-luks-btrfs.nix) | UEFI + LUKS2 + btrfs subvolumes (`/`, `/home`, `/nix`, `/persist`, swap) |

## Using one

```nix
# hosts/my-machine/configuration.nix
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ../examples/disko-luks-btrfs.nix
  ];

  # Both examples default to /dev/nvme0n1. Override for your machine:
  disko.devices.disk.main.device = "/dev/sda";
}
```

Find the right device first. **disko erases it.**

```bash
lsblk -o NAME,SIZE,MODEL
```

`/dev/sda` is usually SATA, `/dev/nvme0n1` NVMe, `/dev/vda` a VM disk. Confirm
by size and model, not by name — the numbering is not stable across boots.

## Installing

From the NixOS installer ISO, with your config cloned or written to disk:

```bash
# 1. Partition, format, and mount at /mnt — DESTRUCTIVE
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  ./hosts/my-machine/disko.nix

# 2. Confirm it looks right before continuing
mount | grep /mnt
lsblk

# 3. Install
sudo nixos-install --flake .#my-machine
```

The `--mode` values are worth knowing apart:

| Mode                   | Effect                                                 |
| ---------------------- | ------------------------------------------------------ |
| `format`               | Create filesystems on existing partitions              |
| `mount`                | Mount an already-formatted layout at `/mnt`            |
| `destroy,format,mount` | Wipe, partition, format, mount — the full install path |

Use `mount` alone when you are booting the ISO to repair an existing system;
it gets you to a working `/mnt` without touching data.

## Applying to a machine that already exists

You cannot. disko partitions disks; it does not migrate a running system onto
a new layout. Changing the layout of a machine you are already using means
backup, reinstall, restore. Decide on encryption before you install, not after.

What you _can_ change on a live system: swapfile size, mount options, and
adding btrfs subvolumes. Those go through the normal `nixos-rebuild`.

## Choosing a layout

**ext4** — boring and fine. Pick it if you have no specific reason not to.

**btrfs subvolumes** — one pool shared between `/`, `/home` and `/nix`, so
none can fill up while another sits half empty. Also gives you snapshots.
Costs a little performance on databases and VM images.

**LUKS** — if the machine leaves your house, encrypt it. A laptop without
full-disk encryption hands over every credential on it to whoever picks it up.

**`/persist`** — only meaningful with impermanence (wiping `/` on every boot).
The LUKS example creates it because adding a subvolume later is more work than
ignoring an empty one. Not using impermanence? Leave it alone; it costs nothing.

## What encryption does not cover

`/boot` cannot be encrypted — the firmware has to read it — so the kernel and
initrd sit there in the clear. Someone with physical access and time can modify
them to capture your passphrase on the next boot.

Closing that requires Secure Boot with your own keys
([lanzaboote](https://github.com/nix-community/lanzaboote)), which is out of
scope here. Full-disk encryption protects a powered-off machine against theft.
It does not protect against a machine you left unattended and came back to.

## Troubleshooting

**Boot hangs, never asks for the passphrase.** The LUKS partition exists but
nothing declared it. This is what disko prevents; if you see it, you are
booting a system that was partitioned by hand.

**`/boot` out of space.** 512M ESPs fill after a handful of generations. Both
examples use 1G. Recover by garbage collecting old generations:
`sudo nix-collect-garbage -d && sudo nixos-rebuild boot --flake .#my-machine`.

**Two definitions of `fileSystems."/"`.** Your generated
`hardware-configuration.nix` still contains the blocks disko now owns. Delete
its `fileSystems` and `swapDevices` sections; keep
`boot.initrd.availableKernelModules` and the `hardware.cpu.*` lines.

**Wrong device wiped.** There is no recovery. Check `lsblk` before every run.

## Further reading

- [disko upstream docs](https://github.com/nix-community/disko/tree/master/docs)
- [Example layouts](https://github.com/nix-community/disko/tree/master/example) — ZFS, LVM, RAID, bcachefs
- [NixOS install walkthrough with disko](https://nixos.asia/en/nixos-install-disko)
