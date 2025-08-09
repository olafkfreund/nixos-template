# test-vm Home Configuration
# Generated using: just new-host test-vm vm-guest
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

  # Add any test-vm-specific home-manager settings here
}
