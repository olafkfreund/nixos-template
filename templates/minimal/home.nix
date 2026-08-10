# Your user's configuration: packages, dotfiles, program settings.
#
# The split that confuses everyone at first:
#   configuration.nix  -> the machine   (services, boot, users, drivers)
#   home.nix           -> you on it     (your shell, editor, git identity)
#
# A package here is on YOUR PATH only. A package in configuration.nix is on
# everyone's, including root's. When in doubt, put it here.
{ pkgs, ... }:

{
  home.username = "me";
  home.homeDirectory = "/home/me";

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    htop
  ];

  # Home Manager writes real config files from these. `programs.git.enable`
  # generates ~/.config/git/config -- so do not also hand-edit that file, it
  # is a symlink into the store and will be replaced on the next rebuild.
  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  programs.bash.enable = true;

  programs.starship.enable = true;

  # Home Manager's own stateVersion, same rule as the system one: set it once
  # to the release you started on, then leave it alone.
  home.stateVersion = "26.05";
}
