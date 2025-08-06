{ lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    # Core modules
    ../modules/core

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

  # System packages available on all hosts
  environment.systemPackages = with pkgs; [
    # Essential tools
    wget
    curl
    git
    vim
    htop
    tree
    unzip
    zip

    # System utilities
    pciutils
    usbutils
    psmisc
    lshw

    # Network tools
    dig
    iputils # Provides ping, traceroute, etc.
  ];

  # Enable documentation
  documentation = {
    enable = true;
    man.enable = true;
    info.enable = true;
  };

  # System version
  system.stateVersion = lib.mkDefault "25.05";
}
