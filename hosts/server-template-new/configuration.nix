# Server Configuration - New Preset-based Approach
# Minimal, secure server configuration
{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/presets
  ];

  # System identification
  networking.hostName = "server-template";

  # Use the server preset
  modules.presets = {
    enable = true;
    preset = "server";

    # Server-specific customizations
    customizations = {
      # Enable specific services for this server
      services = {
        # Web server
        nginx = {
          enable = true;
          virtualHosts."localhost" = {
            root = "/var/www";
          };
        };

        # Database (optional)
        postgresql = {
          enable = false; # Enable per deployment
          package = pkgs.postgresql_15;
        };

        # Monitoring
        prometheus.exporters.node.enable = true;
      };

      # Server-specific networking
      networking = {
        # Open HTTP/HTTPS ports
        firewall.allowedTCPPorts = [ 22 80 443 9100 ]; # SSH, HTTP, HTTPS, Node Exporter

        # Static IP configuration (adjust per deployment)
        interfaces.ens18 = {
          ipv4.addresses = [{
            address = "192.168.1.100";
            prefixLength = 24;
          }];
        };
        defaultGateway = "192.168.1.1";
        nameservers = [ "1.1.1.1" "8.8.8.8" ];
      };

      # Server-specific packages
      environment.systemPackages = with pkgs; [
        # Server management
        docker-compose
        kubernetes

        # Monitoring
        prometheus
        grafana

        # Backup
        restic
        borgbackup

        # Security
        fail2ban
        ufw
      ];
    };
  };

  # Server-specific users (define per deployment)
  users.users.deploy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      # Add SSH keys here
    ];
  };
}
