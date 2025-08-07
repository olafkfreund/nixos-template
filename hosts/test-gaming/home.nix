# test-gaming Home Configuration  
# Generated using: just new-host test-gaming gaming
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

  # Add any test-gaming-specific home-manager settings here
}
