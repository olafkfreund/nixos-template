{ lib }:

{
  hostname,
  system ? "x86_64-linux",
  inputs,
  modules ? [ ],
  overlays ? [ ],
}:

lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs hostname;
    inherit (inputs.self) outputs;
  };

  modules = [
    # Base system configuration
    ({ pkgs, ... }: {
      networking.hostName = hostname;
      nixpkgs = {
        config.allowUnfree = true;
        overlays = overlays ++ [ inputs.self.overlays.default ];
      };

      # Nix configuration
      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          auto-optimise-store = true;
        };

        # Automatic garbage collection
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };

      # System packages available to all configurations
      environment.systemPackages = with pkgs; [
        git
        vim
        curl
        wget
        htop
        tree
      ];
    })

    # Common configuration
    ../hosts/common.nix

  ]
  ++ modules;
}
