{ ... }:

{
  imports = [
    ./sops.nix
    ./firewall.nix
    # ./agenix.nix  # Deprecated - use sops.nix instead
  ];
}
