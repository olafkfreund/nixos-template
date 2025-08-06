# Secrets Management with Agenix

This directory contains encrypted secrets managed by [agenix](https://github.com/ryantm/agenix), an age-based secret management tool for NixOS.

## Overview

Agenix provides secure, declarative secret management by:

- Encrypting secrets with age (modern encryption tool)
- Storing encrypted secrets in git (safe to commit)
- Automatically decrypting secrets on target systems
- Managing access control through public keys

## Quick Start

### 1. Setup Agenix

Add agenix to your flake inputs:

```nix
# flake.nix
inputs = {
  agenix.url = "github:ryantm/agenix";
  # ... other inputs
};
```

Enable the agenix module:

```nix
# hosts/yourhost/default.nix
modules.security.agenix = {
  enable = true;
  secrets = {
    "user-password" = {
      file = ../../secrets/user-password.age;
      owner = "root";
      mode = "0400";
    };
  };
};
```

### 2. Generate Keys

**Generate your personal age key**:

```bash
# From SSH key (recommended)
ssh-to-age < ~/.ssh/id_ed25519.pub

# Or generate new age key
age-keygen -o ~/.config/age/key.txt
```

**Get system host key**:

```bash
# On target system
sudo ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

### 3. Configure Access

Edit `secrets.nix` with your keys:

```nix
let
  alice = "age1xyz...";           # Your age public key
  laptop = "age1host123...";      # System's age public key
in
{
  "user-password.age".publicKeys = [ alice laptop ];
}
```

### 4. Create and Edit Secrets

**Create/edit a secret**:

```bash
agenix -e user-password.age
```

**First time setup**:

```bash
# Set identity file location
export EDITOR="vim"
agenix -i ~/.config/age/key.txt -e user-password.age
```

## Directory Structure

```
secrets/
├── secrets.nix              # Secret access control configuration
├── keys/                     # Public keys directory
│   ├── README.md            # Key management documentation
│   └── .gitignore           # Ignore private keys
├── *.age                    # Encrypted secret files (safe to commit)
├── .gitignore              # Ignore decrypted secrets
└── README.md               # This file
```

## Configuration

### Basic Module Configuration

```nix
modules.security.agenix = {
  enable = true;

  # Global defaults
  secretsPath = "/run/agenix";       # Where secrets are decrypted
  secretsMode = "0400";              # Default file permissions
  secretsOwner = "root";             # Default owner
  secretsGroup = "root";             # Default group

  # Identity files for decryption
  identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];

  # Secrets configuration
  secrets = {
    "wifi-password" = {
      file = ../../secrets/wifi-password.age;
      owner = "networkmanager";
      group = "networkmanager";
      mode = "0440";
    };

    "user-password" = {
      file = ../../secrets/user-password.age;
      path = "/run/agenix/user-password";
    };
  };
};
```

### Advanced Configuration

```nix
modules.security.agenix = {
  enable = true;

  # Custom installation type
  installationType = "system";  # or "activation"

  # Multiple identity sources
  identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/home/alice/.ssh/id_ed25519"
  ];

  secrets = {
    # Database credentials
    "database-url" = {
      file = ../../secrets/database-url.age;
      owner = "postgres";
      group = "postgres";
      mode = "0400";
    };

    # SSL certificates
    "ssl-cert" = {
      file = ../../secrets/ssl-cert.age;
      path = "/var/lib/ssl/cert.pem";
      owner = "nginx";
      group = "nginx";
      mode = "0444";
    };

    # API keys for services
    "api-keys" = {
      file = ../../secrets/api-keys.age;
      owner = "myservice";
      group = "myservice";
    };
  };
};
```

## Common Use Cases

### User Passwords

```nix
# In your host configuration
modules.security.agenix = {
  secrets."user-password" = {
    file = ../../secrets/user-password.age;
  };
};

# Use in user configuration
users.users.alice = {
  hashedPasswordFile = config.age.secrets."user-password".path;
};
```

### Network Configuration

```nix
# WiFi password
modules.security.agenix = {
  secrets."wifi-password" = {
    file = ../../secrets/wifi-password.age;
    owner = "networkmanager";
    group = "networkmanager";
  };
};

# Use in networking configuration
networking.wireless = {
  networks."MyNetwork" = {
    pskFile = config.age.secrets."wifi-password".path;
  };
};
```

### Service Secrets

```nix
# Database password
modules.security.agenix = {
  secrets."postgres-password" = {
    file = ../../secrets/postgres-password.age;
    owner = "postgres";
    group = "postgres";
  };
};

# Use in service configuration
services.postgresql = {
  ensureUsers = [
    {
      name = "myapp";
      ensurePermissions."DATABASE myapp" = "ALL PRIVILEGES";
      passwordFile = config.age.secrets."postgres-password".path;
    }
  ];
};
```

### Backup Secrets

```nix
# Restic backup password
modules.security.agenix = {
  secrets."restic-password" = {
    file = ../../secrets/restic-password.age;
    owner = "backup";
    group = "backup";
  };
};

# Use with restic
services.restic.backups.home = {
  passwordFile = config.age.secrets."restic-password".path;
  repository = "rest:https://backup.example.com/";
  paths = [ "/home" ];
};
```

## Secret Management Workflow

### Adding New Secrets

1. **Update secrets.nix**:

   ```nix
   "new-secret.age".publicKeys = [ users.alice systems.laptop ];
   ```

2. **Create the secret**:

   ```bash
   agenix -e new-secret.age
   ```

3. **Add to host configuration**:

   ```nix
   modules.security.agenix.secrets."new-secret" = {
     file = ../../secrets/new-secret.age;
     owner = "myservice";
   };
   ```

4. **Use in configuration**:

   ```nix
   services.myservice = {
     secretFile = config.age.secrets."new-secret".path;
   };
   ```

### Rotating Secrets

1. **Edit existing secret**:

   ```bash
   agenix -e existing-secret.age
   ```

2. **System will automatically reload** on next rebuild

### Adding New Systems/Users

1. **Get new public key**:

   ```bash
   ssh-to-age < /path/to/new/key.pub
   ```

2. **Update secrets.nix**:

   ```nix
   let
     newSystem = "age1new...";
   in
   {
     "secret.age".publicKeys = [ existingKeys... newSystem ];
   }
   ```

3. **Re-encrypt secrets**:

   ```bash
   agenix -r  # Rekey all secrets
   ```

## Security Best Practices

### Key Management

1. **Use SSH-derived keys** when possible for consistency
2. **Store private keys securely** (never commit to git)
3. **Use hardware security modules** for high-security environments
4. **Rotate keys regularly** and update secret encryption

### Access Control

1. **Principle of least privilege** - only necessary keys per secret
2. **Separate user and system keys** for different access patterns
3. **Regular access audits** of who can decrypt what secrets
4. **Document key ownership** and purpose

### Operational Security

1. **Secure workstation** for secret management operations
2. **Audit secret access** through system logs
3. **Backup private keys** securely and separately
4. **Test disaster recovery** procedures

## Troubleshooting

### Common Issues

**Secret not decrypting**:

```bash
# Check identity files
ls -la /etc/ssh/ssh_host_*_key

# Verify age keys
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Check permissions
ls -la /run/agenix/
```

**Permission errors**:

```bash
# Check service ownership
systemctl status agenix-secretname

# Verify file permissions
ls -la /run/agenix/secretname
```

**Missing agenix command**:

```bash
# Install agenix
nix-shell -p agenix

# Or add to system packages
environment.systemPackages = [ pkgs.agenix ];
```

### Debugging Commands

```bash
# List all secrets
agenix -l

# Check secret content (after decryption)
sudo cat /run/agenix/secret-name

# View system logs
journalctl -u agenix-*

# Test age decryption manually
age -d -i /etc/ssh/ssh_host_ed25519_key secret.age
```

## Integration Examples

### Complete Host Configuration

```nix
# hosts/laptop/default.nix
{ config, ... }: {
  imports = [ ../../modules/security/agenix.nix ];

  modules.security.agenix = {
    enable = true;

    secrets = {
      "user-password" = {
        file = ../../secrets/user-password.age;
      };

      "wifi-password" = {
        file = ../../secrets/wifi-password.age;
        owner = "networkmanager";
        group = "networkmanager";
      };

      "ssh-key" = {
        file = ../../secrets/ssh-key.age;
        owner = "alice";
        group = "users";
        path = "/home/alice/.ssh/id_ed25519";
      };
    };
  };

  # Use secrets in configuration
  users.users.alice = {
    hashedPasswordFile = config.age.secrets."user-password".path;
  };

  networking.wireless.networks."MyWiFi" = {
    pskFile = config.age.secrets."wifi-password".path;
  };
}
```

### Service Integration

```nix
# Example: Nextcloud with secrets
services.nextcloud = {
  enable = true;
  config = {
    adminpassFile = config.age.secrets."nextcloud-admin-password".path;
    dbpassFile = config.age.secrets."nextcloud-db-password".path;
  };
};

modules.security.agenix.secrets = {
  "nextcloud-admin-password" = {
    file = ../../secrets/nextcloud-admin-password.age;
    owner = "nextcloud";
    group = "nextcloud";
  };

  "nextcloud-db-password" = {
    file = ../../secrets/nextcloud-db-password.age;
    owner = "nextcloud";
    group = "nextcloud";
  };
};
```

## Migration from Other Secret Management

### From sops-nix

1. **Extract existing secrets**:

   ```bash
   sops -d secrets.yaml > decrypted-secrets.yaml
   ```

2. **Convert to agenix**:

   ```bash
   # For each secret
   echo "secret-value" | agenix -e secret-name.age
   ```

3. **Update configurations** to use agenix paths

### From manual secret files

1. **Encrypt existing secrets**:

   ```bash
   agenix -e existing-secret.age < /path/to/existing/secret
   ```

2. **Update file paths** in configurations
3. **Remove old secret files** after verification

## Additional Resources

- [Agenix Repository](https://github.com/ryantm/agenix)
- [Age Specification](https://age-encryption.org/)
- [SSH to Age Conversion](https://github.com/Mic92/ssh-to-age)
- [NixOS Secrets Management](https://nixos.wiki/wiki/Comparison_of_secret_managing_schemes)
