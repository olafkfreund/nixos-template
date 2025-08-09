{ ... }:

{
  imports = [
    ./agenix.nix    # Standardized on agenix for secrets management
    ./firewall.nix
    ./hardening.nix  # Advanced security hardening
    # ./sops.nix   # Legacy - migrated to agenix
  ];
}
