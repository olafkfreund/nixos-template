# Home Manager configuration for macOS Laptop VM
# VM user environment

{ config, pkgs, lib, inputs, outputs, ... }:

{
  # This is a VM configuration, so we just import common home configuration
  imports = [
    ../../common/home
  ];

  # VM-specific overrides
  home = {
    username = "laptop-user";
    homeDirectory = "/home/laptop-user";
    stateVersion = "24.11";
  };

  # VM-specific packages
  home.packages = with pkgs; [
    # VM guest tools
    spice-vdagent
    
    # Laptop simulation tools
    acpi
    powertop
    
    # Development tools for macOS VM testing
    git
    vim
    curl
    wget
  ];
}