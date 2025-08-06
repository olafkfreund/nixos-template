{ lib, ... }:

{
  imports = [
    ./guest-optimizations.nix
    ./microvm.nix
    ./qemu.nix
  ];
}