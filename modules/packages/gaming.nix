# Gaming applications and utilities
# Game launchers, streaming, and content creation
{
  pkgs,
  lib,
  config,
  ...
}:

{
  # Guarded, because `imports` in Nix is unconditional: modules/presets/gaming.nix
  # imports this file, so without an enable option its package list applied to
  # every host that pulled in ../../modules -- including servers.
  options.modules.packages.gaming.enable =
    lib.mkEnableOption "gaming package collection (Steam, Lutris, Heroic)";

  config = lib.mkIf config.modules.packages.gaming.enable {
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
  };
}
