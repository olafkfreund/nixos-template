# WSL2 Network Configuration
# Optimized networking settings for WSL2 environment

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.wsl.networking;
in

{
  options.modules.wsl.networking = {
    enable = mkEnableOption "WSL2 networking optimizations";

    dnsConfig = mkOption {
      type = types.enum [ "wsl" "custom" "auto" ];
      default = "auto";
      description = ''
        DNS configuration mode:
        - wsl: Use WSL's generated resolv.conf
        - custom: Use custom DNS servers
        - auto: Auto-detect best configuration
      '';
    };

    customDnsServers = mkOption {
      type = types.listOf types.str;
      default = [ "8.8.8.8" "1.1.1.1" "8.8.4.4" "1.0.0.1" ];
      description = "Custom DNS servers (used when dnsConfig = custom)";
    };

    networkOptimizations = mkOption {
      type = types.bool;
      default = true;
      description = "Enable network performance optimizations for WSL2";
    };

    firewallConfig = mkOption {
      type = types.enum [ "disabled" "minimal" "standard" ];
      default = "disabled";
      description = ''
        Firewall configuration for WSL2:
        - disabled: No firewall (Windows firewall handles protection)
        - minimal: Basic protection
        - standard: Standard NixOS firewall rules
      '';
    };

    portForwarding = mkOption {
      type = types.attrsOf types.port;
      default = { };
      example = { ssh = 22; http = 8080; };
      description = "Port forwarding configuration for development services";
    };
  };

  config = mkIf cfg.enable {
    # DNS Configuration
    networking = {
      # Use WSL's built-in networking by default
      useNetworkd = false;
      useDHCP = true;

      # DNS configuration based on mode
      nameservers = mkIf (cfg.dnsConfig == "custom") cfg.customDnsServers;

      # Firewall configuration
      firewall = {
        enable = cfg.firewallConfig != "disabled";

        # Firewall TCP ports based on configuration
        allowedTCPPorts = mkMerge [
          # Minimal firewall rules for WSL2
          (mkIf (cfg.firewallConfig == "minimal") [
            22 # SSH
          ])

          # Standard firewall rules
          (mkIf (cfg.firewallConfig == "standard") [
            22 # SSH
            80 # HTTP
            443 # HTTPS
            8080 # Alternative HTTP
          ])

          # Custom port forwarding
          (mkIf (cfg.firewallConfig != "disabled") (attrValues cfg.portForwarding))
        ];
      };
    };

    # Network optimizations for WSL2
    boot.kernel.sysctl = mkIf cfg.networkOptimizations {
      # TCP optimizations for WSL2
      "net.core.rmem_default" = 262144;
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_default" = 262144;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";

      # Network buffer optimizations
      "net.core.netdev_max_backlog" = 5000;
      "net.ipv4.tcp_window_scaling" = 1;
      "net.ipv4.tcp_timestamps" = 1;
      "net.ipv4.tcp_sack" = 1;

      # WSL2-specific optimizations
      "net.ipv4.ip_local_port_range" = "32768 65535";
      "net.ipv4.tcp_fin_timeout" = 30;
    };

    # DNS resolution optimizations
    environment.etc."resolv.conf.wsl" = mkIf (cfg.dnsConfig == "auto") {
      text = ''
        # WSL2 DNS configuration
        nameserver 172.16.0.1
        nameserver 8.8.8.8
        nameserver 1.1.1.1
        
        # Search domains
        search localdomain
        
        # Options for faster resolution
        options timeout:2 attempts:3 rotate
      '';
    };

    # Network monitoring and debugging tools
    environment.systemPackages = with pkgs; [
      # Network utilities
      netcat-gnu
      nmap
      iperf3
      tcpdump
      wireshark-cli

      # DNS utilities
      dig
      host
      nslookup

      # Network debugging
      traceroute
      mtr
      ping

      # WSL-specific networking tools
      iproute2

      # Network diagnostic script
      (writeShellScriptBin "wsl-network-diagnostics" ''
        exec /etc/wsl-scripts/network-diagnostics.sh "$@"
      '')
    ];

    # Systemd service for network optimization
    systemd.services.wsl-network-setup = {
      description = "WSL2 Network Setup and Optimization";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # WSL2 network setup script
        echo "Setting up WSL2 network optimizations..."
        
        # Configure network interfaces
        ${pkgs.iproute2}/bin/ip link set dev eth0 mtu 1500 || echo "Could not set MTU"
        
        # Enable TCP BBR congestion control if available
        if [ -f /proc/sys/net/ipv4/tcp_congestion_control ]; then
          echo bbr > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "BBR not available"
        fi
        
        echo "WSL2 network setup completed"
      '';
    };

    # Development server helper service
    systemd.services.wsl-port-forward = mkIf (cfg.portForwarding != { }) {
      description = "WSL2 Port Forwarding Helper";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Port forwarding information for Windows
        echo "WSL2 Port Forwarding Information:"
        ${concatStringsSep "\n" (mapAttrsToList (name: port: ''
          echo "Service: ${name} - Port: ${toString port}"
          echo "  Access from Windows: localhost:${toString port}"
        '') cfg.portForwarding)}
      '';
    };

    # Network diagnostic script
    environment.etc."wsl-scripts/network-diagnostics.sh" = {
      text = ''
        #!/bin/bash
        # WSL2 Network Diagnostics
        
        echo "=== WSL2 Network Diagnostics ==="
        echo
        
        echo "Network Interfaces:"
        ip addr show
        echo
        
        echo "Routing Table:"
        ip route show
        echo
        
        echo "DNS Configuration:"
        cat /etc/resolv.conf
        echo
        
        echo "DNS Resolution Test:"
        nslookup google.com
        echo
        
        echo "Network Connectivity Test:"
        ping -c 3 8.8.8.8
        echo
        
        echo "Port Listening:"
        netstat -tlnp
        echo
        
        echo "WSL2 Host IP:"
        cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1
        echo
      '';
      mode = "0755";
    };

  };
}
