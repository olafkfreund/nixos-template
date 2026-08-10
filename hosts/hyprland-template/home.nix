# Home Manager configuration for the hyprland template.
#
# The hyprland configuration itself lives in the shared profile as structured
# settings, so this file only carries what is specific to this user.
{ ... }:

{
  imports = [
    ../../home/profiles/base.nix
    ../../home/profiles/hyprland.nix
  ];

  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  programs.git.settings.user = {
    name = "Hyprland User";
    email = "user@example.com";
  };
}
