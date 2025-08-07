# HOSTNAME Home Configuration  
# Generated using: just new-host HOSTNAME PRESET
{ config, pkgs, ... }:

{
  imports = [
    ../../home/users/user.nix
  ];

  # Host-specific home configuration
  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "25.05";
  };

  # Add any HOSTNAME-specific home-manager settings here
}
