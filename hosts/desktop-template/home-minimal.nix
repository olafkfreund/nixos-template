# Minimal Desktop Home Manager Configuration
# Clean alternative using shared package sets

{ config, pkgs, lib, ... }:

{
  # Import base user configuration and package sets
  imports = [
    ../../home/users/user.nix
    ../../home/packages/development.nix
    ../../home/packages/desktop-productivity.nix
    ../../home/packages/gaming.nix
  ];

  # Override user information
  home = {
    username = "user";
    homeDirectory = lib.mkForce "/home/user";
    stateVersion = "25.05";

    # Add only host-specific packages here
    packages = with pkgs; [
      # Host-specific additions
      gparted
    ];

    # Session variables
    sessionVariables = {
      EDITOR = "code";
      BROWSER = "firefox";
      TERMINAL = "gnome-terminal";
      NODE_OPTIONS = "--max-old-space-size=8192";
      NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
    };
  };

  # Override Git configuration for desktop use
  programs.git = {
    userName = lib.mkForce "Desktop User";
    userEmail = lib.mkForce "user@example.com";
    extraConfig = {
      credential.helper = "store";
      rerere.enabled = true;
    };
  };
}
