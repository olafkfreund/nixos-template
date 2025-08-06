# Example agenix secrets configuration for desktop host
{ config, ... }:

{
  # Enable agenix secrets management
  modules.security.agenix = {
    enable = true;
    
    # Desktop-specific secrets
    secrets = {
      # User password
      "user-password" = {
        file = ../../secrets/user-password.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      
      # WiFi network password
      "wifi-password" = {
        file = ../../secrets/wifi-password.age;
        owner = "networkmanager";
        group = "networkmanager";
        mode = "0440";
      };
      
      # SSH private key for user
      "ssh-private-key" = {
        file = ../../secrets/ssh-private-key.age;
        owner = "user";
        group = "users";
        mode = "0400";
        path = "/home/user/.ssh/id_ed25519";
      };
      
      # Email configuration
      "email-password" = {
        file = ../../secrets/email-password.age;
        owner = "user";
        group = "users";
        mode = "0400";
      };
      
      # Development secrets
      "github-token" = {
        file = ../../secrets/github-token.age;
        owner = "user";
        group = "users";
        mode = "0400";
      };
      
      # VPN configuration
      "vpn-config" = {
        file = ../../secrets/vpn-config.age;
        owner = "root";
        group = "root";
        mode = "0400";
        path = "/etc/openvpn/client.conf";
      };
      
      # Backup encryption key
      "restic-password" = {
        file = ../../secrets/restic-password.age;
        owner = "backup";
        group = "backup";
        mode = "0400";
      };
    };
  };
  
  # Use secrets in system configuration
  users.users.user = {
    hashedPasswordFile = config.age.secrets."user-password".path;
  };
  
  # WiFi network with secret password
  networking.wireless = {
    enable = true;
    networks = {
      "MyHomeWiFi" = {
        pskFile = config.age.secrets."wifi-password".path;
      };
    };
  };
  
  # Backup service using encrypted password
  services.restic.backups.home = {
    enable = true;
    passwordFile = config.age.secrets."restic-password".path;
    repository = "rest:https://backup.example.com/";
    paths = [ "/home/user" ];
    timerConfig = {
      OnCalendar = "daily";
    };
  };
  
  # Create backup user for restic
  users.users.backup = {
    isSystemUser = true;
    group = "backup";
  };
  users.groups.backup = {};
}