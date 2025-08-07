{ lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    # Core modules
    ../modules/core

    # Core system packages (essential tools for all hosts)
    ../modules/packages/core-system.nix

    # Home Manager integration  
    inputs.home-manager.nixosModules.home-manager
  ];

  # Home Manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    # Pass inputs to Home Manager
    extraSpecialArgs = {
      inherit inputs outputs;
    };
  };

  # Enable flakes system-wide
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Core packages are now provided by ../modules/packages/core-system.nix

  # Enable documentation
  documentation = {
    enable = true;
    man.enable = true;
    info.enable = true;
  };

  # System version
  system.stateVersion = lib.mkDefault "25.05";
}
