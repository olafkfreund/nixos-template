# Security Modules

This directory contains NixOS security modules including secrets management, authentication, and security hardening configurations.

## Modules

### agenix.nix

Age-based secrets management module for secure handling of sensitive configuration data.

#### Features

**Secure Secret Management**:

- Age-based encryption for secrets
- Declarative secret configuration
- Automatic decryption on target systems
- Public key-based access control

**System Integration**:

- Seamless NixOS integration
- Systemd service integration
- Proper file permissions and ownership
- Symlink or direct file installation

**Key Management**:

- SSH host key integration
- User key support
- Multiple identity sources
- Key rotation support

#### Configuration

Enable agenix secrets management:

```nix
modules.security.agenix = {
  enable = true;

  # Global settings
  secretsPath = "/run/agenix";
  secretsMode = "0400";
  secretsOwner = "root";
  secretsGroup = "root";

  # Identity files for decryption
  identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
  ];

  # Secrets configuration
  secrets = {
    "user-password" = {
      file = ../../secrets/user-password.age;
      owner = "root";
      mode = "0400";
    };

    "wifi-password" = {
      file = ../../secrets/wifi-password.age;
      owner = "networkmanager";
      group = "networkmanager";
      mode = "0440";
    };
  };
};
```

#### Advanced Configuration

**Custom Installation Type**:

```nix
modules.security.agenix = {
  installationType = "system";  # or "activation"

  secrets = {
    "database-password" = {
      file = ../../secrets/database-password.age;
      owner = "postgres";
      group = "postgres";
      path = "/var/lib/postgresql/password";
      symlink = false;  # Direct file instead of symlink
    };
  };
};
```

**Multiple Identity Sources**:

```nix
modules.security.agenix = {
  identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/home/admin/.ssh/id_ed25519"
    "/var/lib/secrets/master.key"
  ];
};
```

#### Quick Start

1. **Add agenix to flake inputs** (already included):

   ```nix
   inputs.agenix.url = "github:ryantm/agenix";
   ```

1. **Run setup script**:

   ```bash
   just setup-secrets
   ```

1. **Configure secrets in host**:

   ```nix
   imports = [ ../../modules/security/agenix.nix ];

   modules.security.agenix = {
     enable = true;
     secrets."user-password".file = ../../secrets/user-password.age;
   };
   ```

1. **Create and edit secrets**:

   ```bash
   just new-secret user-password
   just edit-secret wifi-password
   ```

1. **Use in configuration**:

   ```nix
   users.users.alice = {
     hashedPasswordFile = config.age.secrets."user-password".path;
   };
   ```

#### Common Use Cases

**User Authentication**:

```nix
# Secret configuration
modules.security.agenix.secrets."user-password" = {
  file = ../../secrets/user-password.age;
};

# Usage
users.users.alice = {
  hashedPasswordFile = config.age.secrets."user-password".path;
};
```

**Network Configuration**:

```nix
# WiFi password
modules.security.agenix.secrets."wifi-password" = {
  file = ../../secrets/wifi-password.age;
  owner = "networkmanager";
  group = "networkmanager";
};

# Usage
networking.wireless.networks."MyNetwork" = {
  pskFile = config.age.secrets."wifi-password".path;
};
```

**Service Secrets**:

```nix
# Database password
modules.security.agenix.secrets."postgres-password" = {
  file = ../../secrets/postgres-password.age;
  owner = "postgres";
  group = "postgres";
};

# Usage
services.postgresql = {
  ensureUsers = [{
    name = "myapp";
    passwordFile = config.age.secrets."postgres-password".path;
  }];
};
```

**SSL/TLS Certificates**:

```nix
# Certificate and key
modules.security.agenix.secrets = {
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
};

# Usage
services.nginx.virtualHosts."example.com" = {
  sslCertificate = config.age.secrets."ssl-cert".path;
  sslCertificateKey = config.age.secrets."ssl-key".path;
};
```

#### Key Management

**Generating Keys**:

```bash
# Generate age key from SSH key
ssh-to-age < ~/.ssh/id_ed25519.pub

# Generate new age key
age-keygen -o ~/.config/age/key.txt

# Get host key
sudo ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

**Key Configuration**:

```nix
# In secrets/secrets.nix
let
  users = {
    alice = "age1xyz...";
    bob = "age1abc...";
  };

  systems = {
    laptop = "age1host123...";
    server = "age1host456...";
  };
in
{
  "secret.age".publicKeys = [ users.alice systems.laptop ];
}
```

#### Management Commands

The template includes convenient management commands:

```bash
# Setup agenix
just setup-secrets

# Create/edit secrets
just new-secret my-password
just edit-secret existing-password

# List and manage
just list-secrets
just rekey-secrets
just show-decrypted

# Validation
just check-secrets
```

#### Security Best Practices

**Access Control**:

- Use principle of least privilege for secret access
- Separate user and system keys
- Regular key rotation and re-encryption
- Document key ownership and purpose

**Operational Security**:

- Secure workstation for secret management
- Backup private keys separately and securely
- Audit secret access through system logs
- Test disaster recovery procedures

**Key Storage**:

- Never commit private keys to version control
- Use proper file permissions (600) for private keys
- Consider hardware security modules for high-security environments
- Maintain secure backups of private keys

#### Integration Examples

**Complete Host Setup**:

```nix
# Host configuration with secrets
{ config, ... }: {
  imports = [ ../../modules/security/agenix.nix ];

  modules.security.agenix = {
    enable = true;
    secrets = {
      "user-password".file = ../../secrets/user-password.age;
      "root-password".file = ../../secrets/root-password.age;
      "wifi-password" = {
        file = ../../secrets/wifi-password.age;
        owner = "networkmanager";
        group = "networkmanager";
      };
    };
  };

  # Use secrets in configuration
  users.users = {
    alice.hashedPasswordFile = config.age.secrets."user-password".path;
    root.hashedPasswordFile = config.age.secrets."root-password".path;
  };

  networking.wireless.networks."HomeNetwork" = {
    pskFile = config.age.secrets."wifi-password".path;
  };
}
```

**Service Integration**:

```nix
# Nextcloud with secrets
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
  };
  "nextcloud-db-password" = {
    file = ../../secrets/nextcloud-db-password.age;
    owner = "nextcloud";
  };
};
```

#### Troubleshooting

**Common Issues**:

_Secret not decrypting_:

```bash
# Check identity files exist
ls -la /etc/ssh/ssh_host_*_key

# Verify permissions
sudo ls -la /run/agenix/

# Check systemd services
systemctl status agenix-*
```

_Permission errors_:

```bash
# Check file ownership
ls -la /run/agenix/secret-name

# Verify service configuration
systemctl status agenix-secret-name
```

_Missing agenix command_:

```bash
# Install agenix
nix-shell -p agenix

# Or use setup script
just setup-secrets
```

**Debugging**:

```bash
# Manual decryption test
age -d -i /etc/ssh/ssh_host_ed25519_key secret.age

# Check logs
journalctl -u agenix-*

# Validate configuration
just check-secrets
```

#### Migration

**From Other Secret Management**:

1. **Export existing secrets**:

   ```bash
   # From sops-nix
   sops -d secrets.yaml > decrypted-secrets.yaml

   # From files
   cat /path/to/existing/secret
   ```

1. **Encrypt with agenix**:

   ```bash
   echo "secret-value" | agenix -e secret-name.age
   ```

1. **Update configurations**:
   - Replace file paths with `config.age.secrets."name".path`
   - Update service configurations
   - Remove old secret files after verification

#### Directory Structure

The agenix integration creates this structure:

```
secrets/
├── secrets.nix              # Access control configuration
├── keys/                     # Public keys (safe to commit)
│   ├── users/               # User public keys
│   └── systems/             # Host public keys
├── *.age                    # Encrypted secrets (safe to commit)
└── README.md                # Usage documentation

/run/agenix/                 # Runtime decrypted secrets
├── secret1                  # Decrypted secret files
└── secret2                  # (never commit these paths)
```

## Additional Security Modules

Future security modules may include:

- **hardening.nix** - System hardening configuration
- **firewall.nix** - Advanced firewall rules
- **audit.nix** - Security auditing and logging
- **apparmor.nix** - Application sandboxing
- **selinux.nix** - SELinux configuration

## Contributing

When adding new security modules:

1. Follow the established pattern with comprehensive options
1. Include proper documentation and examples
1. Ensure secure defaults
1. Add appropriate assertions and validation
1. Include troubleshooting information
