{ ... }:

{
  imports = [
    # ./sops.nix  # Temporarily disabled for testing - requires sops-nix
    ./firewall.nix
    # ./agenix.nix  # Deprecated - use sops.nix instead
  ];
}
