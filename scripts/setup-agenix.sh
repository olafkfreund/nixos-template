#!/usr/bin/env bash

# Agenix Setup Script
# This script helps set up agenix secrets management for the NixOS template

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$TEMPLATE_ROOT/secrets"

print_header() {
  echo -e "${BLUE}"
  echo "=================================="
  echo "     Agenix Setup Script"
  echo "=================================="
  echo -e "${NC}"
}

print_step() {
  echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
  print_step "Checking dependencies..."

  local missing_deps=()

  # Check for required tools
  for cmd in age ssh-to-age nix; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    print_error "Missing dependencies: ${missing_deps[*]}"
    echo "Please install missing dependencies and try again."
    echo "You can use: nix-shell -p age ssh-to-age"
    exit 1
  fi

  print_info "All dependencies found ✓"
}

generate_age_key() {
  print_step "Generating age key..."

  local age_key_dir="$HOME/.config/age"
  local age_key_file="$age_key_dir/key.txt"

  # Create age directory if it doesn't exist
  mkdir -p "$age_key_dir"
  chmod 700 "$age_key_dir"

  if [ -f "$age_key_file" ]; then
    print_warning "Age key already exists at $age_key_file"
    read -p "Do you want to create a new key? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 0
    fi
    mv "$age_key_file" "$age_key_file.backup.$(date +%s)"
    print_info "Backed up existing key"
  fi

  # Generate new age key
  age-keygen -o "$age_key_file"
  chmod 600 "$age_key_file"

  print_info "Age key generated at $age_key_file"
  print_warning "Please backup this key securely!"
}

get_age_public_key() {
  local age_key_file="$HOME/.config/age/key.txt"

  if [ ! -f "$age_key_file" ]; then
    print_error "Age key not found at $age_key_file"
    return 1
  fi

  # Extract public key from private key file
  grep -o 'age1[a-z0-9]*' "$age_key_file" | head -1
}

get_ssh_age_keys() {
  print_step "Converting SSH keys to age format..."

  local ssh_key_paths=(
    "$HOME/.ssh/id_ed25519.pub"
    "$HOME/.ssh/id_rsa.pub"
  )

  local age_keys=()

  for ssh_key in "${ssh_key_paths[@]}"; do
    if [ -f "$ssh_key" ]; then
      local age_key
      age_key=$(ssh-to-age <"$ssh_key" 2>/dev/null || true)
      if [ -n "$age_key" ]; then
        age_keys+=("$age_key")
        print_info "Converted SSH key: $(basename "$ssh_key") -> $age_key"
      fi
    fi
  done

  printf '%s\n' "${age_keys[@]}"
}

get_host_age_keys() {
  print_step "Getting host SSH keys..."

  local host_key_paths=(
    "/etc/ssh/ssh_host_ed25519_key.pub"
    "/etc/ssh/ssh_host_rsa_key.pub"
  )

  local age_keys=()

  for host_key in "${host_key_paths[@]}"; do
    if [ -f "$host_key" ]; then
      local age_key
      age_key=$(sudo cat "$host_key" | ssh-to-age 2>/dev/null || true)
      if [ -n "$age_key" ]; then
        age_keys+=("$age_key")
        print_info "Converted host key: $(basename "$host_key") -> $age_key"
      fi
    fi
  done

  printf '%s\n' "${age_keys[@]}"
}

setup_secrets_nix() {
  print_step "Setting up secrets.nix..."

  local secrets_file="$SECRETS_DIR/secrets.nix"

  if [ -f "$secrets_file" ]; then
    print_warning "secrets.nix already exists"
    read -p "Do you want to update it with your keys? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      return 0
    fi
  fi

  # Get user keys
  local user_age_key
  user_age_key=$(get_age_public_key)

  # local ssh_age_keys
  # readarray -t ssh_age_keys < <(get_ssh_age_keys) # Currently unused

  # Get host keys
  local host_age_keys
  readarray -t host_age_keys < <(get_host_age_keys)

  # Get hostname
  local hostname
  hostname=$(hostname)

  # Create updated secrets.nix
  cat >"$secrets_file" <<EOF
let
  # User public keys
  users = {
    $(whoami) = "$user_age_key";
    # Add more users here
  };

  # System/host public keys
  systems = {
    $hostname = "${host_age_keys[0]:-}";
    # Add more systems here
  };

  # Helper functions for common key combinations
  allUsers = builtins.attrValues users;
  allSystems = builtins.attrValues systems;
  
in
{
  # Example secrets configuration
  # Each secret specifies which keys can decrypt it
  
  # User passwords
  "user-password.age".publicKeys = [ users.$(whoami) systems.$hostname ];
  "root-password.age".publicKeys = [ systems.$hostname ];
  
  # SSH keys
  "ssh-private-key.age".publicKeys = [ users.$(whoami) systems.$hostname ];
  
  # Network configuration
  "wifi-password.age".publicKeys = [ systems.$hostname ];
  
  # Application secrets  
  "database-password.age".publicKeys = [ systems.$hostname ];
  "api-key.age".publicKeys = [ users.$(whoami) systems.$hostname ];
  
  # Email configuration
  "email-password.age".publicKeys = [ users.$(whoami) systems.$hostname ];
  
  # Backup and sync
  "restic-password.age".publicKeys = [ systems.$hostname ];
}
EOF

  print_info "secrets.nix updated with your keys"
}

create_example_secret() {
  print_step "Creating example secret..."

  local secret_name="example-password.age"
  local secret_path="$SECRETS_DIR/$secret_name"

  if [ -f "$secret_path" ]; then
    print_warning "Example secret already exists"
    return 0
  fi

  # Create a temporary file with example content
  local temp_file
  temp_file=$(mktemp)
  echo "my-secret-password-123" >"$temp_file"

  # Set up agenix environment
  export AGENIX_SECRETS="$SECRETS_DIR/secrets.nix"

  # Encrypt the secret
  if command -v agenix &>/dev/null; then
    agenix -e "$secret_name" -i "$HOME/.config/age/key.txt" <"$temp_file"
  else
    print_warning "agenix command not found, using age directly"
    local user_key
    user_key=$(get_age_public_key)
    age -r "$user_key" -o "$secret_path" "$temp_file"
  fi

  # Clean up
  rm -f "$temp_file"

  print_info "Example secret created: $secret_name"
}

show_next_steps() {
  print_step "Setup complete!"
  echo
  print_info "Next steps:"
  echo "1. Edit secrets using: agenix -e secret-name.age"
  echo "2. Add secrets to your host configuration:"
  echo "   modules.security.agenix.enable = true;"
  echo "3. Configure secrets in your host's secrets.nix file"
  echo "4. Reference secrets in your NixOS configuration"
  echo
  print_info "Example usage:"
  echo "  agenix -e user-password.age"
  echo "  agenix -e wifi-password.age"
  echo
  print_info "Files created:"
  echo "  - $HOME/.config/age/key.txt (your private key - keep secure!)"
  echo "  - $SECRETS_DIR/secrets.nix (key configuration)"
  echo "  - $SECRETS_DIR/example-password.age (example encrypted secret)"
  echo
  print_warning "Important: Backup your age private key securely!"
}

main() {
  print_header

  # Create secrets directory if it doesn't exist
  mkdir -p "$SECRETS_DIR"
  mkdir -p "$SECRETS_DIR/keys"

  check_dependencies
  generate_age_key
  setup_secrets_nix
  create_example_secret
  show_next_steps
}

# Check if script is being sourced or executed
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
