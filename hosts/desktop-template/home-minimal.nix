# Minimal Home Manager Configuration
# Essential settings without excessive customization

{ config, pkgs, lib, ... }:

{
  home = {
    username = "user";
    homeDirectory = "/home/user";
    stateVersion = "25.05";

    # Core applications
    packages = with pkgs; [
      firefox
      vscode
      git
      htop
    ];
  };

  # Essential programs
  programs = {
    git = {
      enable = true;
      userName = "User";
      userEmail = "user@example.com";
    };

    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ll = "ls -la";
        gs = "git status";
        ga = "git add";
        gc = "git commit";
      };
    };

    firefox.enable = true;
    vscode.enable = true;
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
  };

  # XDG user directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
