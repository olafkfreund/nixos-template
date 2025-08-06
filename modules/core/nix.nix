{ config, lib, pkgs, inputs, ... }:

{
  nix = {
    settings = {
      # Enable flakes and new nix command
      experimental-features = [ "nix-command" "flakes" ];
      
      # Optimise storage automatically
      auto-optimise-store = true;
      
      # Build configuration
      # Note: Unfree packages are controlled via nixpkgs.config.allowUnfree
      
      # Binary cache configuration
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      
      # Build users
      max-jobs = "auto";
      
      # Keep build dependencies
      keep-derivations = true;
      keep-outputs = true;
    };
    
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    
    # Registry for legacy nix commands
    registry = (lib.mapAttrs (_: flake: { inherit flake; })) inputs;
    
    # Pin nixpkgs flake to system nixpkgs
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
  
  # Allow users in the wheel group to use nix
  nix.settings.trusted-users = [ "root" "@wheel" ];
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = lib.mkDefault true;
}