# VM Guest Preset
# Optimized for running as a virtual machine guest
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.presets;
  isVmGuest = cfg.enable && cfg.preset == "vm-guest";
in

{
  imports = lib.mkIf isVmGuest [
    ../core
    ../desktop
    ../virtualization/vm-guest.nix
  ];

  config = lib.mkIf isVmGuest {

    # VM-optimized hardware settings
    modules.hardware.power-management = lib.mkDefault {
      enable = true;
      profile = "vm";
      # VMs don't need aggressive power management
      cpuGovernor = "ondemand";
      enableThermalManagement = false;
    };

    # Lightweight desktop for VMs
    modules.desktop = lib.mkDefault {
      audio.enable = true;
      gnome = {
        enable = true;
        # Minimal GNOME for better VM performance
        removeDefaultPackages = true;
      };
    };

    # VM guest optimizations
    modules.virtualization.vm-guest.enable = lib.mkDefault true;

    # VM-optimized services (preset configuration)
    services = {
      # Disable unnecessary services in VMs (VMs don't have batteries/thermal)
      upower.enable = false; # No battery management needed
      thermald.enable = false; # No thermal management needed

      # VM guest services (essential for VM operation)
      spice-vdagentd.enable = true;
      qemuGuest.enable = true;

      # X11 forwarding support (keep mkDefault - not everyone needs SSH)
      openssh = {
        enable = lib.mkDefault true;
        settings.X11Forwarding = lib.mkDefault true;
      };
    };

    # VM-optimized boot parameters (preset configuration)
    boot = {
      kernelParams = [
        # VM optimizations
        "quiet"
        "splash"
        # Disable hardware features not available in VMs
        "noapic"
        "acpi=off"
      ];

      # Fast boot for VMs (keep mkDefault - users may want grub menu)
      loader.timeout = lib.mkDefault 1;

      # VM-specific modules (essential for VM operation)
      kernelModules = [
        "virtio_net"
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
        "9p"
        "9pnet_virtio"
      ];

      # Initialize VM-specific hardware early (required for boot)
      initrd.kernelModules = [
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
        "virtio_net"
      ];
    };

    # VM hardware configuration (preset configuration)
    hardware = {
      # Basic OpenGL for VM (keep mkDefault - some VMs may not support)
      opengl.enable = lib.mkDefault true;

      # Disable features not relevant for VMs
      bluetooth.enable = lib.mkForce false;
      enableAllFirmware = false; # VMs don't need proprietary firmware
    };

    # Network configuration for VMs (preset configuration)
    networking = {
      networkmanager.enable = true;
      # Simple firewall for VM
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ]; # SSH for VM management
      };
    };

    # VM-appropriate packages (lightweight)
    environment.systemPackages = with pkgs; lib.mkDefault [
      # Essential VM tools
      firefox
      gnome.gnome-terminal

      # File management
      gnome.nautilus

      # Text editing
      gedit

      # System utilities
      htop

      # VM guest utilities
      spice-vdagent

      # Development basics
      git
      vim
    ];

    # VM-specific optimizations (preset configuration)
    fileSystems = {
      # Optimize for virtual disks (keep mkDefault - affects root filesystem)
      "/" = {
        options = lib.mkDefault [ "noatime" "discard" ];
      };
    };

    # Systemd optimizations for VMs (preset configuration)
    systemd.extraConfig = ''
      DefaultTimeoutStartSec=30s
      DefaultTimeoutStopSec=10s
    '';

    # Memory management for VMs (keep mkDefault - memory config is sensitive)
    zramSwap = {
      enable = lib.mkDefault true;
      memoryPercent = lib.mkDefault 25;
    };

    # User customizations can be applied in the host configuration
    # by simply adding more configuration after the preset import
  };
}
