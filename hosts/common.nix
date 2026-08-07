{
  lib,
  inputs,
  outputs,
  ...
}:

{
  imports = [
    # Core modules
    ../modules/core
    ../modules/hardware
    ../modules/services

    # Core system packages (essential tools for all hosts)
    ../modules/packages/core-system.nix

    # Home Manager integration
    inputs.home-manager.nixosModules.home-manager
  ];

  # Enable advanced NixOS features
  modules = {
    core.nixOptimization.enable = lib.mkDefault true;
    hardware.detection.enable = lib.mkDefault true;
    services.monitoring.enable = lib.mkDefault false; # Enable per-host as needed
  };

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
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Core packages are now provided by ../modules/packages/core-system.nix

  # Enable documentation
  documentation = {
    enable = true;
    man.enable = true;
    info.enable = true;
  };

  # NOTE: `system.stateVersion` is deliberately NOT set here. It is defined once,
  # in ../modules/core/system-identification.nix (imported above via
  # ../modules/core), which also handles the different value nix-darwin expects.
  # Defining it in both places meant two `mkDefault`s at equal priority — fine
  # only while the two happened to agree, and a hard evaluation error the moment
  # they drifted apart.
}
