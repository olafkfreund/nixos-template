# Agenix Secrets Management

This template uses [agenix](https://github.com/ryantm/agenix) for secure, declarative secrets management. Agenix encrypts secrets with age encryption and integrates seamlessly with NixOS.

## Quick Start

### 1. Generate Age Keys

```bash
# Generate a new age key
mkdir -p ~/.config/age
age-keygen > ~/.config/age/key.txt

# Or convert existing SSH key to age format
ssh-to-age < ~/.ssh/id_ed25519.pub
```

### 2. Configure Secrets

Edit `secrets/secrets.nix` and add your public keys:

```nix
let
  # Add your actual public keys
  myUser = "age1xyz...";  # Your age public key
  myHost = "age1abc...";  # Your host's public key
in {
  "user-password.age".publicKeys = [ myUser myHost ];
  "database-password.age".publicKeys = [ myHost ];
}
```

### 3. Create Secrets

```bash
# Install agenix CLI
nix profile install github:ryantm/agenix

# Create/edit secrets
agenix -e user-password.age
agenix -e database-password.age
```

### 4. Use in NixOS Configuration

```nix
{ config, ... }: {
  # Enable agenix module
  modules.security.agenix.enable = true;

  # Define secrets
  age.secrets = {
    user-password = {
      file = ../secrets/user-password.age;
      mode = "0400";
      owner = "user";
    };

    database-password = {
      file = ../secrets/database-password.age;
      mode = "0400";
      owner = "postgres";
    };
  };

  # Use secrets in services
  services.postgresql = {
    enable = true;
    authentication = "host all all 127.0.0.1/32 md5";
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE USER myapp WITH PASSWORD '${config.age.secrets.database-password.path}';
    '';
  };
}
```

## Advanced Usage

### Environment Variables

```nix
systemd.services.myapp = {
  serviceConfig = {
    # Load secret as environment variable
    EnvironmentFile = config.age.secrets.myapp-env.path;
  };
};
```

### User Passwords

```nix
users.users.myuser = {
  hashedPasswordFile = config.age.secrets.user-password.path;
};
```

### SSH Host Keys

```nix
services.openssh = {
  enable = true;
  hostKeys = [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
};

# Decrypt SSH host key
age.secrets.ssh-host-key = {
  file = ../secrets/ssh-host-key.age;
  path = "/etc/ssh/ssh_host_ed25519_key";
  mode = "0600";
  owner = "root";
};
```

### Backup and Sync

```nix
# Restic backup with encrypted password
services.restic.backups.home = {
  repository = "b2:mybucket:/backups/home";
  passwordFile = config.age.secrets.restic-password.path;
  paths = [ "/home" ];
};
```

## Key Management Best Practices

### 1. Key Rotation

```bash
# Generate new key
age-keygen > ~/.config/age/key-new.txt

# Re-encrypt all secrets with new key
agenix --rekey
```

### 2. Multi-User Access

```nix
# Allow multiple users to access a secret
"shared-secret.age".publicKeys = [
  users.alice
  users.bob
  systems.server
];
```

### 3. Environment-Specific Secrets

```nix
# Development secrets
"dev-api-key.age".publicKeys = [ users.developer systems.dev-server ];

# Production secrets (more restricted)
"prod-api-key.age".publicKeys = [ systems.prod-server ];
```

### 4. Host-Specific Secrets

```nix
# Different database passwords per environment
"db-password-dev.age".publicKeys = [ systems.dev-server ];
"db-password-prod.age".publicKeys = [ systems.prod-server ];
```

## Migration from SOPS

If migrating from sops-nix:

1. Export existing secrets:

```bash
sops -d secrets.yaml > decrypted-secrets.json
```

2. Create age secrets:

```bash
# For each secret in the JSON
echo "secret-value" | agenix -e secret-name.age
```

3. Update NixOS configuration:

```nix
# Replace sops references
# sops.secrets.mysecret = { ... };
age.secrets.mysecret = { file = ../secrets/mysecret.age; };

# Update secret paths
# config.sops.secrets.mysecret.path
config.age.secrets.mysecret.path
```

## Troubleshooting

### Permission Issues

```bash
# Check secret file permissions
sudo ls -la /run/agenix/

# Verify age key permissions
ls -la ~/.config/age/key.txt  # Should be 600
```

### Key Problems

```bash
# Test decryption
age --decrypt -i ~/.config/age/key.txt secrets/test.age

# Verify public key conversion
ssh-to-age < ~/.ssh/id_ed25519.pub
```

### Service Failures

```bash
# Check agenix systemd service
systemctl status agenix-user-password

# View logs
journalctl -u agenix-*
```

## Security Considerations

1. **Key Storage**: Store age keys securely, never commit to git
1. **File Permissions**: Secrets are created with mode 400 by default
1. **User Access**: Only specified users can read decrypted secrets
1. **Rotation**: Regularly rotate keys and secrets
1. **Backup**: Securely backup age private keys

## Examples

See `hosts/desktop-template/configuration.nix` for practical examples of agenix usage in a complete system configuration.
