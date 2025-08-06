{ lib, ... }:

{
  imports = [
    ./boot.nix
    ./locale.nix  
    ./networking.nix
    ./nix.nix
    ./security.nix
    ./users.nix
  ];
}