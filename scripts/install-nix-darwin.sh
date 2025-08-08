#!/usr/bin/env bash
# nix-darwin Installation Script
# Installs and configures nix-darwin with Home Manager integration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

log_step() {
  echo -e "${PURPLE}🔧 $1${NC}"
}

# Main header
echo -e "${BLUE}🍎 nix-darwin Installation${NC}"
echo "=========================="
echo ""

# Check if we're on macOS
if [[ $OSTYPE != "darwin"* ]]; then
  log_error "This script is designed for macOS only."
  exit 1
fi

# Detect Mac architecture
if [[ $(uname -m) == "arm64" ]]; then
  ARCH="aarch64"
  ARCH_DESC="Apple Silicon (M1/M2/M3)"
else
  ARCH="x86_64"
  ARCH_DESC="Intel Mac"
fi

log_info "Detected: $ARCH_DESC"
echo ""

# Check for Nix installation
if ! command -v nix >/dev/null 2>&1; then
  log_error "Nix is not installed. Please install Nix first:"
  echo ""
  echo "curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
  echo ""
  exit 1
fi

# Check if flakes are enabled
if ! nix --experimental-features 'nix-command flakes' eval --expr '1 + 1' >/dev/null 2>&1; then
  log_warning "Experimental features may not be enabled."
  log_info "Enabling flakes and nix-command..."
  mkdir -p ~/.config/nix
  echo 'experimental-features = nix-command flakes' >>~/.config/nix/nix.conf
  log_success "Experimental features enabled"
fi

echo ""

# Configuration selection
echo "🎯 Which nix-darwin configuration would you like to install?"
echo ""
echo "Available configurations:"
echo "  1. 🖥️  Desktop    - Full desktop environment with development tools"
echo "  2. 💻 Laptop     - Mobile-optimized configuration for MacBooks"
echo "  3. 🖧  Server     - Headless configuration for development servers"
echo ""

read -p "Choose a configuration (1-3): " config_choice

case $config_choice in
1)
  CONFIG_TYPE="desktop"
  CONFIG_DESC="Desktop"
  ;;
2)
  CONFIG_TYPE="laptop"
  CONFIG_DESC="Laptop"
  ;;
3)
  CONFIG_TYPE="server"
  CONFIG_DESC="Server"
  ;;
*)
  log_error "Invalid choice: $config_choice"
  exit 1
  ;;
esac

# Determine configuration name based on architecture
if [[ $ARCH == "aarch64" ]]; then
  CONFIG_NAME="darwin-${CONFIG_TYPE}"
  SYSTEM="aarch64-darwin"
else
  CONFIG_NAME="darwin-${CONFIG_TYPE}-intel"
  SYSTEM="x86_64-darwin"
fi

log_info "Selected: $CONFIG_DESC configuration for $ARCH_DESC"
log_info "Configuration: $CONFIG_NAME"
echo ""

# Check if nix-darwin is already installed
if command -v darwin-rebuild >/dev/null 2>&1; then
  log_warning "nix-darwin appears to be already installed."
  echo ""
  read -p "Do you want to continue and potentially overwrite the existing installation? (y/N): " overwrite
  if [[ ! $overwrite =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled."
    exit 0
  fi
  echo ""
fi

# Clone or update the template repository
TEMPLATE_DIR="$HOME/.config/nix-darwin"
if [[ -d $TEMPLATE_DIR ]]; then
  log_step "Updating existing template repository..."
  cd "$TEMPLATE_DIR"
  git pull origin main || log_warning "Failed to update repository"
else
  log_step "Cloning nix-darwin template repository..."
  git clone https://github.com/yourusername/nixos-template "$TEMPLATE_DIR"
  cd "$TEMPLATE_DIR"
fi

log_success "Template repository ready"
echo ""

# Backup existing configuration if it exists
if [[ -d "$HOME/.nixpkgs" ]] || [[ -f "$HOME/.config/nixpkgs/config.nix" ]]; then
  log_step "Backing up existing Nix configuration..."
  backup_dir="$HOME/.nixpkgs.backup.$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$backup_dir"

  if [[ -d "$HOME/.nixpkgs" ]]; then
    mv "$HOME/.nixpkgs" "$backup_dir/"
  fi
  if [[ -f "$HOME/.config/nixpkgs/config.nix" ]]; then
    mkdir -p "$backup_dir/.config/nixpkgs"
    mv "$HOME/.config/nixpkgs/config.nix" "$backup_dir/.config/nixpkgs/"
  fi

  log_success "Configuration backed up to $backup_dir"
fi

# Install nix-darwin
log_step "Installing nix-darwin..."

# First time setup - we need to use the bootstrap approach
if ! command -v darwin-rebuild >/dev/null 2>&1; then
  log_info "Performing initial nix-darwin installation..."

  # Create a minimal temporary configuration for bootstrap
  mkdir -p /tmp/nix-darwin-bootstrap
  cat >/tmp/nix-darwin-bootstrap/flake.nix <<EOF
{
  description = "nix-darwin bootstrap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    configuration = { pkgs, ... }: {
      services.nix-daemon.enable = true;
      nix.settings.experimental-features = "nix-command flakes";
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 5;
      nixpkgs.hostPlatform = "$SYSTEM";
    };
  in
  {
    darwinConfigurations."bootstrap" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
EOF

  cd /tmp/nix-darwin-bootstrap
  nix run nix-darwin -- switch --flake .#bootstrap

  log_success "nix-darwin bootstrap complete"
  # Clean up bootstrap directory safely
  if [[ -d "/tmp/nix-darwin-bootstrap" ]]; then
    rm -rf /tmp/nix-darwin-bootstrap
  fi
fi

echo ""

# Now install our actual configuration
log_step "Installing $CONFIG_DESC configuration..."
cd "$TEMPLATE_DIR"

# Check that our configuration exists
if ! nix flake show 2>/dev/null | grep -q "darwinConfigurations.${CONFIG_NAME}"; then
  log_error "Configuration '${CONFIG_NAME}' not found in flake."
  log_info "Available configurations:"
  nix flake show 2>/dev/null | grep "darwinConfigurations" | sed 's/^/  /'
  exit 1
fi

# Apply the configuration
log_info "Building and applying configuration..."
if darwin-rebuild switch --flake ".#${CONFIG_NAME}"; then
  log_success "nix-darwin configuration applied successfully!"
else
  log_error "Failed to apply nix-darwin configuration"
  echo ""
  echo "Troubleshooting tips:"
  echo "  1. Check the error messages above"
  echo "  2. Ensure your user has admin privileges"
  echo "  3. Try running: nix flake check .#darwinConfigurations.${CONFIG_NAME}"
  echo "  4. Check the configuration files in hosts/${CONFIG_TYPE}/"
  exit 1
fi

echo ""

# Set up shell integration
log_step "Setting up shell integration..."

# Ensure nix-darwin is in the shell PATH
if ! echo "$PATH" | grep -q "/run/current-system/sw/bin"; then
  log_info "Adding nix-darwin to shell PATH..."

  # Add to shell profiles
  for shell_profile in "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [[ -f $shell_profile ]] || [[ $shell_profile == "$HOME/.zprofile" ]]; then
      if ! grep -q "/run/current-system/sw/bin" "$shell_profile" 2>/dev/null; then
        echo '' >>"$shell_profile"
        echo '# nix-darwin' >>"$shell_profile"
        echo 'if [ -e /run/current-system/sw/bin ]; then' >>"$shell_profile"
        echo '  export PATH="/run/current-system/sw/bin:$PATH"' >>"$shell_profile"
        echo 'fi' >>"$shell_profile"
        log_info "Updated $shell_profile"
      fi
    fi
  done
fi

log_success "Shell integration configured"
echo ""

# Set up useful aliases and shortcuts
log_step "Creating management shortcuts..."

# Create convenient management scripts
mkdir -p "$HOME/.local/bin"

cat >"$HOME/.local/bin/darwin-update" <<'EOF'
#!/bin/bash
echo "🔄 Updating nix-darwin configuration..."
cd ~/.config/nix-darwin
git pull origin main
nix flake update
darwin-rebuild switch --flake .
echo "✅ nix-darwin update complete!"
EOF

cat >"$HOME/.local/bin/darwin-info" <<'EOF'
#!/bin/bash
echo "🍎 nix-darwin System Information"
echo "==============================="
echo ""
echo "System:"
echo "  Hostname: $(hostname)"
echo "  macOS: $(sw_vers -productVersion)"
echo "  Architecture: $(uname -m)"
echo ""
echo "nix-darwin:"
echo "  Version: $(darwin-rebuild --version 2>/dev/null || echo 'Unknown')"
echo "  Current Generation: $(darwin-rebuild --list-generations | tail -1 | awk '{print $1}' || echo 'Unknown')"
echo ""
echo "Nix:"
echo "  Version: $(nix --version)"
echo "  Store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo 'Unknown')"
echo ""
echo "Home Manager:"
if command -v home-manager >/dev/null; then
    echo "  Status: Installed"
    echo "  Generation: $(home-manager generations | head -1 | awk '{print $5}' 2>/dev/null || echo 'Unknown')"
else
    echo "  Status: Not installed"
fi
echo ""
echo "Configuration:"
echo "  Template: ~/.config/nix-darwin"
echo "  Active Config: $(readlink /run/current-system 2>/dev/null || echo 'Unknown')"
EOF

chmod +x "$HOME/.local/bin/darwin-update" "$HOME/.local/bin/darwin-info"

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  for shell_profile in "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [[ -f $shell_profile ]] || [[ $shell_profile == "$HOME/.zprofile" ]]; then
      if ! grep -q "HOME/.local/bin" "$shell_profile" 2>/dev/null; then
        echo '' >>"$shell_profile"
        echo '# Local binaries' >>"$shell_profile"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >>"$shell_profile"
        break
      fi
    fi
  done
fi

log_success "Management tools installed"
echo ""

# Final success message
log_success "🎉 nix-darwin installation complete!"
echo ""
echo -e "${PURPLE}=== Installation Summary ===${NC}"
echo "Configuration: $CONFIG_DESC ($ARCH_DESC)"
echo "Template Location: $TEMPLATE_DIR"
echo "Configuration Name: $CONFIG_NAME"
echo ""
echo -e "${PURPLE}=== Next Steps ===${NC}"
echo "1. 🔄 Restart your terminal or run: source ~/.zprofile"
echo "2. ℹ️  Run 'darwin-info' for system information"
echo "3. 🔧 Run 'darwin-update' to update your system"
echo "4. 📝 Customize your configuration in: $TEMPLATE_DIR/hosts/$CONFIG_TYPE/"
echo "5. 🔄 Apply changes with: darwin-rebuild switch --flake ~/.config/nix-darwin#$CONFIG_NAME"
echo ""
echo -e "${PURPLE}=== Useful Commands ===${NC}"
echo "• System info: darwin-info"
echo "• Update system: darwin-update"
echo "• Rebuild: darwin-rebuild switch --flake ~/.config/nix-darwin#$CONFIG_NAME"
echo "• List generations: darwin-rebuild --list-generations"
echo "• Rollback: darwin-rebuild --rollback"
echo ""
echo -e "${PURPLE}=== Configuration Files ===${NC}"
echo "• System config: $TEMPLATE_DIR/hosts/$CONFIG_TYPE/configuration.nix"
echo "• Home Manager: $TEMPLATE_DIR/hosts/$CONFIG_TYPE/home.nix"
echo "• Darwin modules: $TEMPLATE_DIR/darwin/"
echo ""

# Offer to restart terminal
echo ""
read -p "Would you like to restart your terminal now to load the new configuration? (y/N): " restart_terminal

if [[ $restart_terminal =~ ^[Yy]$ ]]; then
  log_info "Please restart your terminal or run: source ~/.zprofile"
  log_info "After restart, run 'darwin-info' to verify installation"
else
  log_info "Remember to restart your terminal or run: source ~/.zprofile"
fi

echo ""
log_success "Welcome to nix-darwin! 🚀"
