# Minimal Role Configuration
# Bare minimum setup for resource-constrained environments
{ ... }:

{
  imports = [
    ../common/base.nix
    ../common/git.nix
    ../common/packages/essential.nix
  ];

  # Override base defaults for minimal footprint
  programs = {
    # Disable resource-heavy programs from base
    eza.enable = false;
    fd.enable = false;
    ripgrep.enable = false;
    tree.enable = false;
    
    # Keep only essential bash configuration
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        ".." = "cd ..";
      };
      
      # Minimal history settings
      historySize = 1000;
      historyFileSize = 2000;
    };

    # Minimal git configuration
    git = {
      extraConfig = {
        # Disable resource-intensive features
        delta.enable = false;
        core = {
          editor = "nano";
          pager = "less";
        };
      };
    };
  };

  # Minimal XDG setup
  xdg = {
    enable = true;
    userDirs.enable = false;  # Don't create extra directories
  };

  # Override essential packages with minimal set
  home.packages = [];  # Will be overridden by essential.nix, but can be further reduced per host
}