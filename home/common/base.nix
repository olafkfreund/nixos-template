# Base Home Manager Configuration
# Universal settings that every user needs regardless of role or host
{ lib, ... }:

{
  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Set state version (should match your NixOS version)
  home.stateVersion = lib.mkDefault "25.05";

  # Basic shell configuration
  programs.bash = {
    enable = lib.mkDefault true;

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 10000;
    historyFileSize = 20000;
  };

  # Basic file management
  xdg = {
    enable = true;

    # Clean up home directory
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Essential programs everyone needs
  programs = {
    # Modern directory listing
    eza = {
      enable = lib.mkDefault true;
      enableBashIntegration = true;
      icons = "auto";
      extraOptions = [ "--group-directories-first" "--header" ];
    };

    # Better find command
    fd = {
      enable = lib.mkDefault true;
    };

    # Better grep
    ripgrep = {
      enable = lib.mkDefault true;
    };

    # File tree viewer
    tree = {
      enable = lib.mkDefault true;
    };
  };
}
