# Example Agenix Secrets Configuration
# This example demonstrates how to integrate agenix secrets into a NixOS configuration
# Copy and adapt sections as needed for your specific use case

{ config, pkgs, ... }:

{
  imports = [
    ../../modules/core
    ../../modules/security
    ../../modules/packages
  ];

  # Enable agenix secrets management
  modules.security.agenix = {
    enable = true;
    secretsPath = "/run/agenix"; # Default location for decrypted secrets
    secretsMode = "0400"; # Read-only for owner
    secretsOwner = "root"; # Default owner
  };

  # Define secrets that this system needs
  age.secrets = {
    # User account secrets
    user-password = {
      file = ../../secrets/user-password.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    # SSH host key
    ssh-host-key = {
      file = ../../secrets/ssh-host-key.age;
      path = "/etc/ssh/ssh_host_ed25519_key";
      mode = "0600";
      owner = "root";
      group = "root";
    };

    # Application database password
    postgres-password = {
      file = ../../secrets/database-password.age;
      mode = "0400";
      owner = "postgres";
      group = "postgres";
    };

    # Web service API key
    api-key = {
      file = ../../secrets/api-key.age;
      mode = "0400";
      owner = "nginx";
      group = "nginx";
    };

    # Backup encryption password
    restic-password = {
      file = ../../secrets/restic-password.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    # Wireless network credentials
    wifi-config = {
      file = ../../secrets/wifi-password.age;
      mode = "0400";
      owner = "root";
      group = "root";
    };

    # Email service credentials
    email-password = {
      file = ../../secrets/email-password.age;
      mode = "0400";
      owner = "mail";
      group = "mail";
    };

    # VPN configuration
    wireguard-private-key = {
      file = ../../secrets/vpn-config.age;
      mode = "0400";
      owner = "systemd-network";
      group = "systemd-network";
    };

    # SSL/TLS certificates
    tls-cert = {
      file = ../../secrets/tls-cert.age;
      mode = "0444"; # World-readable (certificates are public)
      owner = "root";
      group = "root";
    };

    tls-key = {
      file = ../../secrets/tls-key.age;
      mode = "0400"; # Private key - very restricted
      owner = "root";
      group = "root";
    };

    # Development environment variables
    dev-env = {
      file = ../../secrets/dev-api-key.age;
      mode = "0400";
      owner = "user";
      group = "users";
    };
  };

  # Example service configurations using secrets

  # 1. User account with encrypted password
  users.users.myuser = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.user-password.path;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # 2. PostgreSQL with secure password
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    authentication = ''
      host all all 127.0.0.1/32 md5
      host all all ::1/128 md5
    '';
    initialScript = pkgs.writeText "postgres-init" ''
      ALTER USER postgres PASSWORD '$(cat ${config.age.secrets.postgres-password.path})';
      CREATE DATABASE myapp;
      CREATE USER myapp_user WITH PASSWORD '$(cat ${config.age.secrets.postgres-password.path})';
      GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp_user;
    '';
  };

  # 3. Nginx with SSL certificates
  services.nginx = {
    enable = true;
    virtualHosts."example.com" = {
      enableACME = false; # Using custom certificates
      forceSSL = true;
      sslCertificate = config.age.secrets.tls-cert.path;
      sslCertificateKey = config.age.secrets.tls-key.path;

      locations."/" = {
        proxyPass = "http://127.0.0.1:3000";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
        '';
      };
    };
  };

  # 4. Backup service with encrypted repository
  services.restic.backups.home = {
    user = "root";
    repository = "b2:mybucket:/backups/home";
    passwordFile = config.age.secrets.restic-password.path;
    paths = [
      "/home"
      "/var/lib"
      "/etc"
    ];
    exclude = [
      "/home/*/.cache"
      "/home/*/.local/share/Trash"
      "**/.git"
      "**/node_modules"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };

  # 5. Email service with encrypted credentials
  services.postfix = {
    enable = true;
    origin = "example.com";
    relayHost = "smtp.gmail.com";
    relayPort = 587;
    config = {
      smtp_use_tls = "yes";
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
    };
  };

  # Create SASL password file from secret
  systemd.services.postfix-sasl-passwd = {
    description = "Create Postfix SASL password file from secret";
    before = [ "postfix.service" ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      echo "smtp.gmail.com:587 user@gmail.com:$(cat ${config.age.secrets.email-password.path})" > /etc/postfix/sasl_passwd
      ${pkgs.postfix}/bin/postmap /etc/postfix/sasl_passwd
      chmod 600 /etc/postfix/sasl_passwd*
    '';
  };

  # 6. WireGuard VPN with encrypted keys
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.0.0.2/24" ];
    privateKeyFile = config.age.secrets.wireguard-private-key.path;
    peers = [
      {
        publicKey = "server-public-key-here";
        endpoint = "vpn.example.com:51820";
        allowedIPs = [ "10.0.0.0/24" ];
        persistentKeepalive = 25;
      }
    ];
  };

  # 7. Systemd service with environment variables from secrets
  systemd.services.myapp = {
    description = "My Application";
    after = [ "network.target" "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "myapp";
      Group = "myapp";
      Restart = "always";
      RestartSec = 10;

      # Load environment variables from secret file
      EnvironmentFile = config.age.secrets.dev-env.path;

      # Additional security
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };

    script = ''
      export DATABASE_URL="postgresql://myapp_user:$(cat ${config.age.secrets.postgres-password.path})@localhost/myapp"
      export API_KEY="$(cat ${config.age.secrets.api-key.path})"

      exec ${pkgs.myapp}/bin/myapp
    '';
  };

  # 8. Wireless networking with encrypted credentials
  networking.wireless = {
    enable = true;
    networks = {
      "MyWiFi" = {
        pskRaw = "$(cat ${config.age.secrets.wifi-config.path})";
      };
    };
  };

  # 9. SSH server with custom host key
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };

    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # Ensure SSH host key is properly decrypted before SSH starts
  systemd.services.sshd.after = [ "agenix-ssh-host-key.service" ];

  # System configuration
  system.stateVersion = "24.05";

  # Enable modules
  modules = {
    core = {
      nixOptimization.enable = true;
      systemId.enable = true;
    };
    security.firewall.enable = true;
    packages.core-apps.enable = true;
  };
}
