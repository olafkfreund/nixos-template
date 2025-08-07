# Gaming applications and tools
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Game launchers and platforms
    lutris
    heroic
    steam-run

    # Gaming utilities
    gamemode
    gamescope
    mangohud
  ];
}