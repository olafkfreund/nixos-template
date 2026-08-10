# A complete NixOS + Home Manager flake in one file.
#
# Created by:  nix flake init -t github:olafkfreund/nixos-template#minimal
#
# This is deliberately the whole thing -- no lib/, no modules/, no profiles.
# Read it top to bottom in two minutes, then grow it when something actually
# hurts. The full template this came from shows where it goes next.
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      # Without this, Home Manager pulls a SECOND nixpkgs and you get two
      # different versions of every package in one system. Always follow.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    {
      # Build with: sudo nixos-rebuild switch --flake .#my-machine
      # The name here must match `networking.hostName` in configuration.nix.
      nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.me = import ./home.nix;
          }
        ];
      };
    };
}
