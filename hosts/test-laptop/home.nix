# test-laptop Home Configuration
# Generated using: just new-host test-laptop laptop
{ ... }:

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

  # Add any test-laptop-specific home-manager settings here
}
