# Server Preset
# Optimized for reliability, security, and headless operation
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.presets;
  isServer = cfg.enable && cfg.preset == "server";
in

{
  imports = [
    ../core
    ../hardware/power-management.nix
    ../security
    ../virtualization/podman.nix
    ../virtualization/libvirt.nix
    ../packages/server-admin.nix
  ];

  config = lib.mkIf isServer {

    # Hardware optimization for server
    modules.hardware.power-management = lib.mkDefault {
      enable = true;
      profile = "server";
      cpuGovernor = "ondemand";
      enableThermalManagement = true;

      server = {
        enableServerOptimizations = true;
        disableWakeOnLan = false;
      };
    };

    # Container support for services
    # Temporarily disable our custom podman module to test NixOS built-in
    # modules.virtualization.podman.enable = lib.mkDefault true;
    # Use NixOS built-in podman module instead
    virtualisation.podman.enable = lib.mkDefault true;
    virtualisation.podman.dockerCompat = lib.mkDefault true;
    virtualisation.containers.enable = lib.mkDefault true;

    modules.virtualization.libvirt.enable = lib.mkDefault true;

    # Server-optimized services (opinionated preset configuration)
    services = {
      # SSH is essential for servers (override security default)
      openssh = {
        enable = true;
        settings = {
          # Secure defaults for server preset
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          KbdInteractiveAuthentication = false;
        };
        ports = [ 22 ];
      };

      # Time synchronization critical for servers
      ntp.enable = true;

      # System monitoring (keep mkDefault - optional service)
      prometheus.exporters.node = {
        enable = lib.mkDefault false; # Enable per-host as needed
      };

      # Note: Enable automatic updates carefully per host
    };

    # Server networking (opinionated server configuration)
    networking = {
      # Use systemd-networkd for servers (keep mkDefault - some prefer NetworkManager)
      useNetworkd = lib.mkDefault true;
      useDHCP = lib.mkDefault false;

      # Firewall essential for servers
      firewall = {
        enable = lib.mkForce true;
        # Restrictive by default - open ports per service (keep mkDefault - users customize)
        allowedTCPPorts = lib.mkDefault [ 22 ]; # SSH only
        allowPing = true; # Standard server behavior
      };

      # Fast DNS servers (opinionated choice)
      nameservers = [ "1.1.1.1" "8.8.8.8" ];
    };

    # Server-optimized boot parameters (preset configuration)
    boot = {
      kernelParams = [
        # Server performance optimizations
        "transparent_hugepage=always"
        "vm.swappiness=1"
        "net.core.default_qdisc=fq"
        "net.ipv4.tcp_congestion_control=bbr"
      ];

      # Faster boot for servers (servers don't need boot menu delays)
      loader.timeout = 1;

      # Enable virtualization modules (common for servers)
      kernelModules = [ "kvm-intel" "kvm-amd" ];
    };

    # Server-specific packages (core tools provided by shared modules)
    environment.systemPackages = with pkgs; lib.mkDefault [
      # Server-specific monitoring tools only
      sysstat
      lsof

      # Container management
      podman-compose

      # Backup tools
      borgbackup
    ];

    # Security hardening for servers (preset configuration)
    security = {
      # Restrict sudo (secure server defaults)
      sudo = {
        enable = true;
        wheelNeedsPassword = true;
      };

      # AppArmor for additional security (keep mkDefault - optional hardening)
      apparmor.enable = lib.mkDefault true;

    };

    # Fail2ban for SSH protection (opinionated server security)
    services.fail2ban = {
      enable = true;
      jails.ssh-iptables = ''
        enabled = true
        filter = sshd
        action = iptables[name=SSH, port=ssh, protocol=tcp]
        logpath = /var/log/auth.log
        maxretry = 5
        bantime = 3600
      '';
    };


    # Disable auto-login (inappropriate for servers)
    services.getty.autologinUser = lib.mkForce null;

    # System optimization
    systemd = {

      # Optimize for server workloads (preset configuration)
      settings.Manager = {
        DefaultTimeoutStopSec = "10s";
        DefaultTimeoutStartSec = "10s";
      };
    };

    # No graphical interface
    services.xserver.enable = lib.mkForce false;

    # User customizations can be applied in the host configuration
    # by simply adding more configuration after the preset import
  };
}
