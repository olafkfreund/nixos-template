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

    # VM-optimized services
    services = {
      # Disable unnecessary services in VMs
      upower.enable = lib.mkDefault false; # No battery management needed
      thermald.enable = lib.mkDefault false; # No thermal management needed

      # VM guest services
      spice-vdagentd.enable = lib.mkDefault true;
      qemuGuest.enable = lib.mkDefault true;

      # X11 forwarding support
      openssh = {
        enable = lib.mkDefault true;
        settings.X11Forwarding = lib.mkDefault true;
      };
    };

    # VM-optimized boot parameters
    boot = {
      kernelParams = lib.mkDefault [
        # VM optimizations
        "quiet"
        "splash"
        # Disable hardware features not available in VMs
        "noapic"
        "acpi=off"
      ];

      # Fast boot for VMs
      loader.timeout = lib.mkDefault 1;

      # VM-specific modules
      kernelModules = lib.mkDefault [
        "virtio_net"
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
        "9p"
        "9pnet_virtio"
      ];

      # Initialize VM-specific hardware early
      initrd.kernelModules = lib.mkDefault [
        "virtio_pci"
        "virtio_blk"
        "virtio_scsi"
        "virtio_net"
      ];
    };

    # VM hardware configuration
    hardware = {
      # Basic OpenGL for VM
      opengl.enable = lib.mkDefault true;

      # Disable features not relevant for VMs
      bluetooth.enable = lib.mkForce false;
      enableAllFirmware = lib.mkDefault false;
    };

    # Network configuration for VMs
    networking = {
      networkmanager.enable = lib.mkDefault true;
      # Simple firewall for VM
      firewall = {
        enable = lib.mkDefault true;
        allowedTCPPorts = lib.mkDefault [ 22 ]; # SSH
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

    # VM-specific optimizations
    fileSystems = {
      # Optimize for virtual disks
      "/" = {
        options = lib.mkDefault [ "noatime" "discard" ];
      };
    };

    # Systemd optimizations for VMs
    systemd.extraConfig = lib.mkDefault ''
      DefaultTimeoutStartSec=30s
      DefaultTimeoutStopSec=10s
    '';

    # Memory management for VMs
    zramSwap = {
      enable = lib.mkDefault true;
      memoryPercent = lib.mkDefault 25;
    };

    # User customizations can be applied in the host configuration
    # by simply adding more configuration after the preset import
  };
}
