# Agenix Keys Directory

This directory contains age public keys for users and systems that can decrypt secrets.

## Key Types

### User Keys
Personal age keys for individual users. These are typically generated from SSH keys or created specifically for secrets management.

### System Keys
Age keys derived from SSH host keys of systems/hosts that need access to secrets.

## Key Management

### Generating User Keys

**From SSH Key**:
```bash
# Convert SSH public key to age public key
ssh-to-age < ~/.ssh/id_ed25519.pub

# Or with explicit conversion
nix-shell -p ssh-to-age --run "ssh-to-age < ~/.ssh/id_ed25519.pub"
```

**Direct Age Key Generation**:
```bash
# Generate a new age key pair
age-keygen -o user-key.txt
# The public key will be printed to stdout
# Store the private key securely
```

### Generating System Keys

**From SSH Host Keys**:
```bash
# On the target system
sudo ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Or remotely
ssh root@hostname 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age
```

### Key Storage

**Public Keys** (safe to commit):
- Store in this `keys/` directory
- Include in `secrets.nix` configuration
- Can be shared publicly

**Private Keys** (NEVER commit):
- Store securely on local systems only
- Use proper file permissions (600)
- Consider hardware security modules

## Directory Structure

```
keys/
├── users/
│   ├── alice.pub          # User public keys
│   ├── bob.pub
│   └── admin.pub
├── systems/
│   ├── laptop.pub         # System public keys
│   ├── server.pub
│   └── desktop.pub
└── README.md              # This file
```

## Usage in secrets.nix

Reference keys in your secrets configuration:

```nix
let
  users = {
    alice = "age1xyz...";    # Content of keys/users/alice.pub
    bob = "age1abc...";      # Content of keys/users/bob.pub
  };

  systems = {
    laptop = "age1host123..."; # Content of keys/systems/laptop.pub
    server = "age1host456..."; # Content of keys/systems/server.pub
  };
in
{
  "my-secret.age".publicKeys = [ users.alice systems.laptop ];
}
```

## Security Notes

1. **Public Key Distribution**: Public keys can be safely committed to git
2. **Private Key Security**: Never commit private keys to version control
3. **Key Rotation**: Regularly rotate keys and re-encrypt secrets
4. **Access Control**: Only include necessary keys for each secret
5. **Backup**: Maintain secure backups of private keys