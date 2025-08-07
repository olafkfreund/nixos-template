# Gaming applications and utilities
# Game launchers, streaming, and content creation
{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Game platforms
    steam
    lutris
    heroic

    # Gaming utilities
    mangohud
    goverlay
    gamemode
    gamescope

    # Game development
    godot_4

    # Content creation and streaming
    obs-studio
    kdePackages.kdenlive
    discord

    # Network analysis for gaming
    wireshark
  ];
}
