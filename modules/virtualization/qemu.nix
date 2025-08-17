{ config, lib, pkgs, ... }:

let
  cfg = config.modules.virtualization.qemu;
in
{
  options.modules.virtualization.qemu = {
    enable = lib.mkEnableOption "QEMU/KVM guest configuration";

    virtioSupport = lib.mkEnableOption "VirtIO driver support" // { default = true; };

    spiceSupport = lib.mkEnableOption "SPICE guest tools" // { default = false; };

    qxlSupport = lib.mkEnableOption "QXL graphics driver" // { default = false; };
  };

  config = lib.mkIf cfg.enable {
    # Enable guest optimizations
    modules.virtualization.guest-optimizations = {
      enable = true;
      qemuGuest = true;
    };

    # Services configuration
    services = {
      # QEMU guest agent for host communication
      qemuGuest.enable = true;

      # SPICE guest tools for better desktop integration
      spice-vdagentd.enable = cfg.spiceSupport;

      # QXL graphics driver
      xserver = lib.mkIf cfg.qxlSupport {
        videoDrivers = [ "qxl" ];
      };
    };

    # VirtIO drivers for better performance
    boot = lib.mkIf cfg.virtioSupport {
      initrd = {
        availableKernelModules = [
          # VirtIO drivers
          "virtio_pci"
          "virtio_scsi"
          "virtio_blk"
          "virtio_net"
          "virtio_balloon"
          "virtio_console"
          "virtio_rng"
        ];

        kernelModules = [
          "virtio_gpu"
        ];
      };

      kernelModules = [
        "kvm"
        "kvm_intel" # or kvm_amd
        "vfio"
        "vfio_pci"
      ];
    };

    # Optimize for QEMU/KVM
    environment.systemPackages = with pkgs; [
      # QEMU guest additions
      qemu-utils
    ] ++ lib.optionals cfg.spiceSupport [
      # SPICE client tools
      spice-vdagent
      spice-gtk
    ];

    # Network configuration optimized for VMs
    networking = {
      # Use predictable interface names
      usePredictableInterfaceNames = true;

      # DHCP on main interface
      interfaces = {
        enp0s3.useDHCP = lib.mkDefault true; # Common QEMU interface
        ens3.useDHCP = lib.mkDefault true; # Alternative naming
      };
    };

    # Filesystem optimizations for QEMU
    fileSystems = {
      "/" = {
        # Use discard for SSD-backed storage
        options = [ "noatime" "discard" ];
      };
    };

    # Security optimizations for VMs
    security = {
      # Allow QEMU guest agent
      polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.machine1.manage-machines" &&
                subject.isInGroup("wheel")) {
                return polkit.Result.YES;
            }
        });
      '';
    };
  };
}
