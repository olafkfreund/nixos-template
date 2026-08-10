# Home Manager configuration for the niri template.
#
# The niri configuration itself lives in the shared profile as structured
# settings, so this file only carries what is specific to this user.
{ ... }:

{
  imports = [
    ../../home/profiles/base.nix
    ../../home/profiles/niri.nix
  ];

  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  programs.git.settings.user = {
    name = "niri User";
    email = "user@example.com";
  };
}
