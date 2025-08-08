# Example usage of the expert NixOS improvements
# This shows how to use the new features in your host configurations

{ config, lib, pkgs, flakeMeta, ... }:

{
  # 1. SOPS Secrets Management
  modules.security.sops = {
    enable = true;
    defaultSopsFile = ./secrets/secrets.yaml; # Your secrets file

    secrets = {
      # Database credentials
      "database/postgres/password" = {
        owner = "postgresql";
        group = "postgresql";
        mode = "0440";
        restartUnits = [ "postgresql.service" ];
      };

      # API keys
      "api/github-token" = {
        owner = "git";
        mode = "0400";
      };

      # SSL certificates
      "ssl/example.com/cert" = {
        owner = "nginx";
        group = "nginx";
        mode = "0444";
        reloadUnits = [ "nginx.service" ];
      };
    };

    # Configuration templates combining multiple secrets
    templates = {
      "app-config" = {
        content = ''
          # Application configuration
          database_url=postgresql://user:${config.sops.placeholder."database/postgres/password"}@localhost/myapp
          github_token=${config.sops.placeholder."api/github-token"}

          # Build information from flake metadata
          build_date="${flakeMeta.buildDate}"
          build_revision="${flakeMeta.flakeShortRev}"
          hostname="${flakeMeta.hostname}"
        '';
        path = "/run/secrets/app.env";
        owner = "myapp";
        group = "myapp";
        mode = "0440";
      };
    };
  };

  # 2. Advanced Firewall Configuration
  modules.security.firewall = {
    enable = true;
    profile = "server"; # or "desktop", "gaming", "development"

    protection = {
      enableDDoSProtection = true;
      enableBruteForceProtection = true;
      enablePortScanning = true;
      maxConnections = 25;
    };

    logging = {
      enable = true;
      level = "warn";
      rateLimit = "10/minute";
    };

    allowedPorts = {
      tcp = [ 8080 9000 ]; # Custom application ports
      udp = [ 51820 ]; # WireGuard VPN
    };

    trustedNetworks = [
      "10.0.0.0/8" # Private network
      "192.168.0.0/16" # Local network
    ];

    # Custom rules for specific needs
    customRules.input = [
      "tcp dport 8443 ip saddr 10.0.0.0/8 accept comment \"Internal HTTPS\""
      "tcp dport 5432 ip saddr 192.168.1.10 accept comment \"Database access\""
    ];

    blacklist = [
      "1.2.3.4" # Block specific malicious IP
      "10.1.1.0/24" # Block entire subnet
    ];
  };

  # 3. Using Flake Metadata in Services
  systemd.services.myapp = {
    description = "My Application (${flakeMeta.profile})";
    environment = {
      # Pass flake metadata to your applications
      BUILD_DATE = flakeMeta.buildDate;
      BUILD_REV = flakeMeta.flakeShortRev;
      HOSTNAME = flakeMeta.hostname;
      PROFILE = flakeMeta.profile;
    };

    serviceConfig = {
      ExecStart = "${pkgs.myapp}/bin/myapp";
      # Use secret from SOPS
      EnvironmentFile = config.sops.templates."app-config".path;
    };
  };

  # 4. System Identification with Metadata
  networking.hostName = flakeMeta.hostname;

  # Set system description with build info
  system.nixos.distroId = "nixos-${flakeMeta.profile}";

  # Custom system banner with metadata
  users.motd = ''

    🏗️  ${flakeMeta.hostname} (${flakeMeta.profile})
    ═══════════════════════════════════════

    Build Date: ${flakeMeta.buildDate}
    Flake Rev:  ${flakeMeta.flakeShortRev}
    System:     ${flakeMeta.system}

    Commands:
    • nixos-info          - Show system information
    • firewall-status     - Check firewall status
    • firewall-manage     - Manage firewall rules

  '';

  # 5. Conditional Configuration Based on Profile
  services.nginx.enable = flakeMeta.profile == "server";
  services.xserver.enable = builtins.elem flakeMeta.profile [ "desktop" "gaming" ];

  # Development tools only on development profile
  environment.systemPackages = with pkgs;
    [ ] ++ lib.optionals (flakeMeta.profile == "development") [
      nodejs
      python3
      vscode
    ];
}

# Usage in flake.nixosConfigurations:
# my-server = mkSystem {
#   hostname = "my-server";
#   profile = "server";  # This gets passed to flakeMeta
#   system = "x86_64-linux";
# };
