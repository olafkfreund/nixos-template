let
  # User public keys - Add your personal age public keys here
  users = {
    # Example user keys (replace with your actual keys)
    alice = "age1xyz..."; # Replace with actual age public key
    bob = "age1abc..."; # Replace with actual age public key
  };

  # System/host public keys - Add your systems' SSH host key age equivalents
  systems = {
    # Example system keys (replace with your actual host keys)
    laptop = "age1host123..."; # Replace with actual converted SSH host key
    server = "age1host456..."; # Replace with actual converted SSH host key
    desktop = "age1host789..."; # Replace with actual converted SSH host key
  };

  # Helper functions for common key combinations
  allSystems = builtins.attrValues systems;

in
{
  # Example secrets configuration
  # Each secret specifies which keys can decrypt it

  # User passwords
  "user-password.age".publicKeys = [ users.alice systems.laptop systems.desktop ];
  "root-password.age".publicKeys = allSystems;

  # SSH keys
  "ssh-private-key.age".publicKeys = [ users.alice systems.laptop ];
  "ssh-config.age".publicKeys = [ users.alice systems.laptop systems.desktop ];

  # Network configuration
  "wifi-password.age".publicKeys = allSystems;
  "vpn-config.age".publicKeys = [ users.alice systems.laptop ];

  # Application secrets  
  "database-password.age".publicKeys = [ systems.server ];
  "api-key.age".publicKeys = [ users.alice systems.server ];
  "jwt-secret.age".publicKeys = [ systems.server ];

  # Email configuration
  "email-password.age".publicKeys = [ users.alice systems.laptop systems.desktop ];
  "smtp-config.age".publicKeys = [ users.alice systems.laptop systems.desktop ];

  # Backup and sync
  "restic-password.age".publicKeys = allSystems;
  "sync-token.age".publicKeys = [ users.alice systems.laptop systems.desktop ];

  # Development secrets
  "github-token.age".publicKeys = [ users.alice systems.laptop systems.desktop ];
  "docker-registry-auth.age".publicKeys = [ systems.server systems.desktop ];

  # Certificates and TLS
  "tls-cert.age".publicKeys = [ systems.server ];
  "tls-key.age".publicKeys = [ systems.server ];
  "ca-cert.age".publicKeys = allSystems;

  # Service-specific secrets
  "nextcloud-password.age".publicKeys = [ systems.server ];
  "matrix-config.age".publicKeys = [ systems.server ];
  "monitoring-token.age".publicKeys = [ systems.server systems.laptop ];
}
