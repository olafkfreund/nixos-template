# Home Manager configuration for macOS Server VM
# VM user environment

{ config, pkgs, lib, inputs, outputs, ... }:

{
  # This is a VM configuration, so we just import common home configuration
  imports = [
    ../../common/home
  ];

  # VM-specific overrides
  home = {
    username = "server-admin";
    homeDirectory = "/home/server-admin";
    stateVersion = "24.11";
  };

  # VM-specific packages (minimal for server)
  home.packages = with pkgs; [
    # VM guest tools
    spice-vdagent

    # Server tools for macOS VM testing
    git
    vim
    curl
    wget
    htop
    tree
  ];
}
