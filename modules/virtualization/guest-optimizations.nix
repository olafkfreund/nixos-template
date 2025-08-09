{ config, lib, pkgs, ... }:

let
  cfg = config.modules.virtualization.guest-optimizations;
in
{
  options.modules.virtualization.guest-optimizations = {
    enable = lib.mkEnableOption "virtualization guest optimizations";

    qemuGuest = lib.mkEnableOption "QEMU guest optimizations";

    disableUnneededServices = lib.mkEnableOption "disable unneeded services for VMs" // { default = true; };

    optimizeForSpeed = lib.mkEnableOption "optimize for VM speed over features" // { default = true; };
  };

  config = lib.mkIf cfg.enable {

    # Optimize kernel for virtualization
    boot = {
      # Use minimal kernel for better performance
      kernelPackages = lib.mkDefault pkgs.linuxPackages;

      # VM-optimized kernel parameters
      kernelParams = [
        # Reduce boot time
        "quiet"
        "loglevel=3"

        # VM optimizations
        "elevator=noop" # Simple I/O scheduler for VMs
        "clocksource=kvm-clock" # Use KVM clock source
        "no_timer_check" # Skip timer checks
        "noreplace-smp" # Don't replace SMP instructions

        # Memory optimizations
        "transparent_hugepage=never"
      ] ++ lib.optionals cfg.optimizeForSpeed [
        # Speed over security
        "mitigations=off"
        "spectre_v2=off"
        "spec_store_bypass_disable=off"
      ];

      # Faster boot
      initrd = {
        systemd.enable = true;
        verbose = false;
      };

      # Disable unnecessary hardware support
      blacklistedKernelModules = [
        # Bluetooth
        "bluetooth"
        "btusb"

        # Wireless
        "iwlwifi"
        "ath9k"
        "rtl8821ce"

        # Sound (if not needed)
        # "snd_hda_intel"
        # "snd_hda_codec_hdmi"
      ];
    };

    # Optimize services for VMs
    services = lib.mkMerge [
      # QEMU guest agent and drivers
      (lib.mkIf cfg.qemuGuest {
        qemuGuest.enable = true;
      })

      # Disable unneeded services
      (lib.mkIf cfg.disableUnneededServices {
        # Disable power management
        thermald.enable = false;
        tlp.enable = false;

        # Disable hardware-specific services
        fwupd.enable = false; # Firmware updates
        udisks2.enable = false; # Disk management

        # Minimal logging
        journald.extraConfig = ''
          Storage=volatile
          RuntimeMaxUse=50M
          SystemMaxUse=100M
        '';
      })
    ];

    # Optimize systemd for VMs
    systemd = {
      # Faster service startup
      settings.Manager = {
        DefaultTimeoutStartSec = "30s";
        DefaultTimeoutStopSec = "10s";
      };

      # Disable unnecessary targets
      targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
    };

    # Memory optimizations
    environment.variables = {
      # Reduce memory usage
      MALLOC_CHECK_ = "0";
    };

    # Minimal filesystem optimizations
    fileSystems = lib.mkIf cfg.optimizeForSpeed {
      "/" = {
        options = [ "noatime" "nodiratime" ];
      };
    };

    # Disable swap unless explicitly needed
    swapDevices = lib.mkDefault [ ];
    zramSwap.enable = lib.mkDefault false;

    # Network optimizations for VMs
    networking = {
      # Use systemd-networkd for better performance
      useNetworkd = lib.mkDefault true;
      useDHCP = false;
    };

    # Optimize network stack
    boot.kernel.sysctl = {
      # TCP optimizations
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

      # Reduce network timeouts
      "net.ipv4.tcp_keepalive_time" = 600;
      "net.ipv4.tcp_keepalive_probes" = 3;
      "net.ipv4.tcp_keepalive_intvl" = 90;
    };
  };
}
