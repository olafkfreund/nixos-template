# WSL-specific modules for NixOS on WSL2
# These modules provide optimizations and integrations specific to WSL environments

{ ... }:

{
  imports = [
    ./interop.nix
    ./networking.nix
    ./optimization.nix
    # ./systemd.nix  # Temporarily disabled due to syntax issues
  ];
}
