# test-workstation Home Configuration  
# Generated using: just new-host test-workstation workstation
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

  # Add any test-workstation-specific home-manager settings here
}
