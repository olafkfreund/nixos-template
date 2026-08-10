# Your user's configuration.
#
#   configuration.nix  -> the machine   (services, boot, drivers, users)
#   home.nix           -> you on it     (shell, editor, git identity, apps)
{ pkgs, ... }:

{
  home.username = "me";
  home.homeDirectory = "/home/me";

  home.packages = with pkgs; [
    # Terminal
    ripgrep
    fd
    jq
    htop

    # Desktop
    # Pick ONE media player, ONE launcher, ONE terminal. Installing several
    # of each is the fastest way to a config you cannot reason about.
    mpv
    alacritty
  ];

  programs.git = {
    enable = true;
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  programs.bash.enable = true;
  programs.starship.enable = true;

  # Prefer a real module over hand-written files where one exists: this is
  # typed, so a typo fails the build instead of silently doing nothing.
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.stateVersion = "26.05";
}
