# Example agenix secrets configuration for server host
{ config, pkgs, ... }:

{
  # Enable agenix secrets management
  modules.security.agenix = {
    enable = true;

    # Server-specific secrets
    secrets = {
      # Root password
      "root-password" = {
        file = ../../secrets/root-password.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      # Database passwords
      "postgres-password" = {
        file = ../../secrets/postgres-password.age;
        owner = "postgres";
        group = "postgres";
        mode = "0400";
      };

      "mysql-password" = {
        file = ../../secrets/mysql-password.age;
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };

      # Web service secrets
      "nextcloud-admin-password" = {
        file = ../../secrets/nextcloud-admin-password.age;
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0400";
      };

      "nextcloud-db-password" = {
        file = ../../secrets/nextcloud-db-password.age;
        owner = "nextcloud";
        group = "nextcloud";
        mode = "0400";
      };

      # API keys and tokens
      "api-key" = {
        file = ../../secrets/api-key.age;
        owner = "webservice";
        group = "webservice";
        mode = "0400";
      };

      "jwt-secret" = {
        file = ../../secrets/jwt-secret.age;
        owner = "webservice";
        group = "webservice";
        mode = "0400";
      };

      # SSL/TLS certificates
      "ssl-cert" = {
        file = ../../secrets/ssl-cert.age;
        owner = "nginx";
        group = "nginx";
        mode = "0444";
        path = "/var/lib/ssl/cert.pem";
      };

      "ssl-key" = {
        file = ../../secrets/ssl-key.age;
        owner = "nginx";
        group = "nginx";
        mode = "0400";
        path = "/var/lib/ssl/key.pem";
      };

      # Email server secrets
      "smtp-password" = {
        file = ../../secrets/smtp-password.age;
        owner = "mail";
        group = "mail";
        mode = "0400";
      };

      # Monitoring secrets
      "monitoring-token" = {
        file = ../../secrets/monitoring-token.age;
        owner = "prometheus";
        group = "prometheus";
        mode = "0400";
      };

      # Backup encryption
      "server-backup-password" = {
        file = ../../secrets/server-backup-password.age;
        owner = "backup";
        group = "backup";
        mode = "0400";
      };
    };
  };

  # User and group configuration
  users = {
    users = {
      root = {
        hashedPasswordFile = config.age.secrets."root-password".path;
      };
      
      webservice = {
        isSystemUser = true;
        group = "webservice";
      };
      
      backup = {
        isSystemUser = true;
        group = "backup";
      };
      
      mail = {
        isSystemUser = true;
        group = "mail";
      };
    };
    
    groups = {
      webservice = { };
      backup = { };
      mail = { };
    };
  };

  # Service configuration with secrets
  services = {
    # Database configuration with secrets
    postgresql = {
      enable = true;
      ensureUsers = [
        {
          name = "nextcloud";
          ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
        }
      ];
      ensureDatabases = [ "nextcloud" ];
    };

    # Nextcloud with secrets
    nextcloud = {
      enable = true;
      package = pkgs.nextcloud29;
      hostName = "cloud.example.com";

      config = {
        adminuser = "admin";
        adminpassFile = config.age.secrets."nextcloud-admin-password".path;

        dbtype = "pgsql";
        dbuser = "nextcloud";
        dbname = "nextcloud";
        dbpassFile = config.age.secrets."nextcloud-db-password".path;
      };
    };

    # Nginx with SSL certificates from secrets
    nginx = {
      enable = true;
      virtualHosts."example.com" = {
        sslCertificate = config.age.secrets."ssl-cert".path;
        sslCertificateKey = config.age.secrets."ssl-key".path;
        enableACME = false; # Using custom certificates
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
      };
    };

    # Backup service with encryption
    restic.backups.system = {
      enable = true;
      passwordFile = config.age.secrets."server-backup-password".path;
      repository = "rest:https://backup.example.com/server";
      paths = [
        "/etc"
        "/var/lib"
        "/home"
      ];
      exclude = [
        "/var/lib/docker"
        "/var/lib/systemd"
      ];
      timerConfig = {
        OnCalendar = "02:00";
      };
    };
  };

}
