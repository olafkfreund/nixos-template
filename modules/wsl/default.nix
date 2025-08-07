# WSL-specific modules for NixOS on WSL2
# These modules provide optimizations and integrations specific to WSL environments

{ lib, ... }:

{
  imports = [
    ./interop.nix
    ./networking.nix
    ./optimization.nix
    ./systemd.nix
  ];
}
