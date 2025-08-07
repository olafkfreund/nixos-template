# Git Configuration
# Common git settings with user-specific overrides
{ lib, ... }:

{
  programs.git = {
    enable = lib.mkDefault true;

    # Default identity (override in host-specific config)
    userName = lib.mkDefault "Change Me";
    userEmail = lib.mkDefault "changeme@example.com";

    # Common git configuration
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = lib.mkDefault "nano";

      # Better diff and merge tools
      diff.colorMoved = "default";
      merge.conflictstyle = "diff3";

      # Useful aliases
      alias = {
        st = "status -s";
        co = "checkout";
        br = "branch";
        ci = "commit";
        ca = "commit -a";
        cm = "commit -m";
        cam = "commit -am";
        lg = "log --oneline --graph --decorate";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
      };
    };

    # Global gitignore for common files
    ignores = [
      # OS generated files
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"

      # Editor files
      "*~"
      "*.swp"
      "*.swo"
      ".vscode/"
      ".idea/"

      # Build artifacts
      "*.o"
      "*.so"
      "*.exe"
      "*.dll"
      "node_modules/"
      "target/"
      "build/"
      "dist/"

      # Temporary files
      "*.tmp"
      "*.temp"
      "*.log"
    ];

    # Delta for better diff viewing
    delta = {
      enable = lib.mkDefault true;
      options = {
        navigate = true;
        line-numbers = true;
        syntax-theme = "Dracula";
      };
    };
  };
}
