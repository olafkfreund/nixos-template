# Home Manager configuration for macOS Desktop VM
# VM user environment

{ config, pkgs, lib, inputs, outputs, ... }:

{
  # This is a VM configuration, so we just import common home configuration
  imports = [
    ../../common/home
  ];

  # VM-specific overrides
  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
    stateVersion = "24.11";
  };

  # VM-specific packages
  home.packages = with pkgs; [
    # VM guest tools
    spice-vdagent
    
    # Development tools for macOS VM testing
    git
    vim
    curl
    wget
  ];
}