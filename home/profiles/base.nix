# Base Home Manager profile
# Common configuration shared across all user environments
{ lib, pkgs, ... }:

{
  home.stateVersion = lib.mkDefault "25.05";

  # Programs configuration consolidated
  programs = {
    # Git configuration with sensible defaults
    git = {
      enable = lib.mkDefault true;

      # Default user info - override in host-specific configs
      userName = lib.mkDefault "User Name";
      userEmail = lib.mkDefault "user@example.com";

      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "vim";
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
        branch.autosetupmerge = "always";
        branch.autosetuprebase = "always";
      };
    };

    # Bash configuration with common settings
    bash = {
      enable = lib.mkDefault true;
      enableCompletion = true;
      historySize = 10000;
      historyFileSize = 20000;
      historyControl = [ "ignoredups" "ignorespace" ];

      shellAliases = {
        # System shortcuts
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";

        # Git shortcuts
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
        gd = "git diff";

        # System monitoring
        psg = "ps aux | grep";
        h = "history";
        j = "jobs -l";

        # Safety aliases
        rm = "rm -i";
        cp = "cp -i";
        mv = "mv -i";

        # Directory shortcuts
        mkdir = "mkdir -pv";
      };

      bashrcExtra = ''
        # Enhanced bash history
        export HISTCONTROL=ignoreboth:erasedups
        export HISTTIMEFORMAT="%F %T "

        # Better directory navigation
        shopt -s autocd
        shopt -s dirspell
        shopt -s cdspell

        # Case-insensitive globbing
        shopt -s nocaseglob

        # Append to history, don't overwrite
        shopt -s histappend

        # Update window size after each command
        shopt -s checkwinsize
      '';
    };

    # Zsh configuration (alternative shell)
    zsh = {
      enable = lib.mkDefault false; # Enable per-host as needed
      enableCompletion = lib.mkDefault true;
      autocd = lib.mkDefault true;

      shellAliases = {
        # Inherit bash aliases and add zsh-specific ones
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        ".." = "cd ..";
        "..." = "cd ../..";
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git log --oneline";
        gd = "git diff";
      };

      history = {
        size = 10000;
        save = 20000;
        ignoreDups = true;
        share = true;
        extended = true;
      };

      initExtra = ''
        # Better directory navigation
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT

        # Improved globbing
        setopt EXTENDED_GLOB
        setopt NO_CASE_GLOB

        # Better completion
        setopt COMPLETE_IN_WORD
        setopt ALWAYS_TO_END
      '';
    };
  };

  # Common environment variables
  home.sessionVariables = {
    EDITOR = lib.mkDefault "vim";
    BROWSER = lib.mkDefault "firefox";
    TERMINAL = lib.mkDefault "alacritty"; # Can be overridden by specialized profiles
  };

  # XDG directories
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
    };
  };
}
