# Hardware configuration for MicroVM
# Minimal configuration for ultra-lightweight virtual machines
# Replace UUIDs with actual values from your VM

{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # Boot and hardware configuration
  boot = {
    # Minimal hardware support
    initrd = {
      availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "virtio_net"
      ];
      kernelModules = [ ];
    };
    extraModulePackages = [ ];

    # Use systemd-boot for faster boot
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkForce 2; # Keep only 2 generations for minimal VM
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkForce 0;
    };

    # Minimal kernel modules
    kernelModules = [ ];
    blacklistedKernelModules = [
      # Audio
      "snd"
      "snd_hda_intel"

      # Bluetooth
      "bluetooth"
      "btusb"

      # Wireless
      "iwlwifi"
      "cfg80211"

      # Graphics
      "drm"
      "i915"
      "nouveau"
      "radeon"

      # USB (if not needed)
      "usbhid"
      "usb_storage"
    ];
  };

  # Single root filesystem (no separate /boot for minimal setup)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-ROOT-UUID";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
      "commit=60" # Reduce write frequency
    ];
  };

  # For UEFI boot (minimal)
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-BOOT-UUID";
    fsType = "vfat";
    options = [ "noatime" ];
  };

  # No swap for MicroVMs
  swapDevices = [ ];

  # Minimal network configuration
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.eth0.useDHCP = lib.mkDefault true;

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Minimal hardware features
  hardware = {
    # No microcode updates for minimal size
    enableRedistributableFirmware = false;

    # No CPU-specific optimizations
    cpu.intel.updateMicrocode = false;
    cpu.amd.updateMicrocode = false;
  };

  # Memory and disk optimization is handled by the actual hypervisor/VM configuration
  # These settings would be configured in your hypervisor management tool
}
