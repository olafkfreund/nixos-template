# A Wayland desktop with encrypted disk, in one flake.
#
# Created by:  nix flake init -t github:olafkfreund/nixos-template#desktop
#
# Same shape as the `minimal` template, plus the three things a desktop
# actually needs and a first-time installer usually cannot give you:
# a Wayland session, working audio, and full-disk encryption.
{
  description = "My NixOS desktop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning, including the LUKS setup the graphical
    # installer cannot do. See disko.nix.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quirks for your exact model. Find yours in the repo's README, then
    # uncomment the matching module below.
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      disko,
      ...
    }:
    {
      nixosConfigurations.my-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix

          disko.nixosModules.disko
          ./disko.nix

          # Your laptop, if it is one of the supported models:
          # nixos-hardware.nixosModules.framework-13-7040-amd
          # nixos-hardware.nixosModules.lenovo-thinkpad-x1-9th-gen
          # nixos-hardware.nixosModules.dell-xps-13-9310

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
