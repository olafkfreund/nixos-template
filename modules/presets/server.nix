# Server Preset
# Optimized for reliability, security, and headless operation
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.presets;
  isServer = cfg.enable && cfg.preset == "server";
in

{
  imports = lib.mkIf isServer [
    ../core
    ../hardware/power-management.nix
    ../security
    ../virtualization/podman.nix
    ../virtualization/libvirt.nix
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
    modules.virtualization.podman.enable = lib.mkDefault true;
    modules.virtualization.libvirt.enable = lib.mkDefault true;

    # Server-optimized services
    services = {
      # SSH is essential for servers
      openssh = {
        enable = lib.mkDefault true;
        settings = {
          PasswordAuthentication = lib.mkDefault false;
          PermitRootLogin = lib.mkDefault "no";
          KbdInteractiveAuthentication = lib.mkDefault false;
        };
        ports = lib.mkDefault [ 22 ];
      };

      # Time synchronization critical for servers
      ntp.enable = lib.mkDefault true;
      
      # System monitoring
      prometheus.exporters.node = {
        enable = lib.mkDefault false; # Enable per-host as needed
      };
      
      # Automatic updates (careful!)
      automatic-timers.enable = lib.mkDefault false;
    };

    # Server networking (more explicit than desktop)
    networking = {
      # Use systemd-networkd for servers (more reliable)
      useNetworkd = lib.mkDefault true;
      useDHCP = lib.mkDefault false;
      
      # Firewall essential for servers
      firewall = {
        enable = lib.mkForce true;
        # Restrictive by default - open ports per service
        allowedTCPPorts = lib.mkDefault [ 22 ]; # SSH only
        allowPing = lib.mkDefault true;
      };
      
      # DNS configuration
      nameservers = lib.mkDefault [ "1.1.1.1" "8.8.8.8" ];
    };

    # Server-optimized boot parameters
    boot = {
      kernelParams = lib.mkDefault [
        # Server performance optimizations
        "transparent_hugepage=always"
        "vm.swappiness=1"
        "net.core.default_qdisc=fq"
        "net.ipv4.tcp_congestion_control=bbr"
      ];
      
      # Faster boot for servers
      loader.timeout = lib.mkDefault 1;
      
      # Enable all kernel modules that might be needed
      kernelModules = lib.mkDefault [ "kvm-intel" "kvm-amd" ];
    };

    # Server system packages (minimal)
    environment.systemPackages = with pkgs; lib.mkDefault [
      # Essential administration
      htop
      iotop
      nethogs
      tcpdump
      
      # Text editing
      vim
      nano
      
      # Network utilities
      wget
      curl
      rsync
      
      # System utilities
      tmux
      screen
      
      # Monitoring
      sysstat
      lsof
      
      # Container management
      podman-compose
      
      # Backup tools
      borgbackup
    ];

    # Security hardening for servers
    security = {
      # Restrict sudo
      sudo = {
        enable = lib.mkDefault true;
        wheelNeedsPassword = lib.mkDefault true;
      };
      
      # AppArmor for additional security
      apparmor.enable = lib.mkDefault true;
      
      # Fail2ban for SSH protection
      fail2ban = {
        enable = lib.mkDefault true;
        jails.ssh-iptables = lib.mkDefault ''
          enabled = true
          filter = sshd
          action = iptables[name=SSH, port=ssh, protocol=tcp]
          logpath = /var/log/auth.log
          maxretry = 5
          bantime = 3600
        '';
      };
    };

    # System optimization
    systemd = {
      # Disable unnecessary services
      services = {
        # Disable graphical services
        getty.autologinUser = lib.mkForce null;
      };
      
      # Optimize for server workloads
      extraConfig = lib.mkDefault ''
        DefaultTimeoutStopSec=10s
        DefaultTimeoutStartSec=10s
      '';
    };

    # No graphical interface
    services.xserver.enable = lib.mkForce false;
    
    # User customizations can be applied in the host configuration
    # by simply adding more configuration after the preset import
  };
}