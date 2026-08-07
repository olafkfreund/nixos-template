#!/usr/bin/env bash
#
# NixOS rebuild script with helpful features
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLAKE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOSTNAME="${HOSTNAME:-$(hostname)}"

# Functions
log() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS] [COMMAND]

Commands:
    switch      Build and switch to new configuration (default)
    test        Test configuration without switching
    boot        Build configuration for next boot
    build       Build configuration without switching
    dry-run     Show what would be built

Options:
    -h, --help      Show this help message
    -H, --host      Specify hostname (default: current hostname)
    -v, --verbose   Enable verbose output
    --no-check      Skip flake checking
    --update        Update flake inputs before rebuild

Examples:
    $0                          # Build and switch
    $0 test                     # Test configuration
    $0 --host server switch     # Build for specific host
    $0 --update switch          # Update and rebuild
EOF
}

# Parse arguments
COMMAND="switch"
VERBOSE=""
NO_CHECK=""
UPDATE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    -H | --host)
      HOSTNAME="$2"
      shift 2
      ;;
    -v | --verbose)
      VERBOSE="--verbose"
      shift
      ;;
    --no-check)
      NO_CHECK="1"
      shift
      ;;
    --update)
      UPDATE="1"
      shift
      ;;
    switch | test | boot | build | dry-run)
      COMMAND="$1"
      shift
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

# Change to flake directory
cd "$FLAKE_DIR"

# Check if flake.nix exists
if [[ ! -f "flake.nix" ]]; then
  error "flake.nix not found in $FLAKE_DIR"
  exit 1
fi

# Update flake inputs if requested
if [[ -n $UPDATE ]]; then
  log "Updating flake inputs..."
  nix flake update
fi

# Check flake if not disabled
if [[ -z $NO_CHECK ]]; then
  log "Checking flake..."
  if ! nix flake check; then
    warning "Flake check failed, but continuing..."
  fi
fi

# Build the configuration
log "Building configuration for host: $HOSTNAME"
log "Command: $COMMAND"

case $COMMAND in
  switch)
    sudo nixos-rebuild switch --flake ".#$HOSTNAME" $VERBOSE
    ;;
  test)
    sudo nixos-rebuild test --flake ".#$HOSTNAME" $VERBOSE
    ;;
  boot)
    sudo nixos-rebuild boot --flake ".#$HOSTNAME" $VERBOSE
    ;;
  build)
    sudo nixos-rebuild build --flake ".#$HOSTNAME" $VERBOSE
    ;;
  dry-run)
    nixos-rebuild dry-run --flake ".#$HOSTNAME" $VERBOSE
    ;;
esac

success "Configuration $COMMAND completed successfully!"

# Show generation info
if [[ $COMMAND == "switch" || $COMMAND == "boot" ]]; then
  log "Current generation:"
  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1
fi
