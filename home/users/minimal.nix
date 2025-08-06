{ config, lib, pkgs, inputs, outputs, ... }:

{
  # Minimal Home Manager configuration for lightweight systems
  
  # User information
  home = {
    username = "minimal";
    homeDirectory = "/home/minimal";
    stateVersion = "25.05";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Minimal Git configuration
  programs.git = {
    enable = true;
    userName = "Minimal User";
    userEmail = "minimal@example.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nano";
    };
  };

  # Lightweight shell configuration
  programs.bash = {
    enable = true;
    
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      l = "ls";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Essential shortcuts
      h = "history";
      c = "clear";
      e = "nano";
      
      # NixOS essentials
      rebuild = "sudo nixos-rebuild switch --flake .";
    };
    
    bashrcExtra = ''
      # Simple prompt
      export PS1="\u@\h:\w\$ "
      
      # Basic history settings
      export HISTSIZE=1000
      export HISTFILESIZE=2000
    '';
  };

  # Essential command line tools only
  programs = {
    # Basic file operations
    bat = {
      enable = true;
      config.theme = "base16";
    };
    
    # Essential for file finding
    fd.enable = true;
    
    # Essential for text search
    ripgrep.enable = true;
    
    # Basic system monitoring
    htop.enable = true;
    
    # SSH for remote access
    ssh = {
      enable = true;
      
      matchBlocks = {
        "server" = {
          hostname = "server.example.com";
          user = "minimal";
        };
      };
    };
  };

  # Minimal package set - only essentials
  home.packages = with pkgs; [
    # Text editors
    nano
    vim
    
    # File operations
    file
    tree
    
    # Archive handling
    unzip
    
    # Network essentials
    curl
    wget
    
    # System information
    lshw
    
    # Process management
    killall
    
    # Text processing
    grep
    sed
    awk
    
    # Basic development
    git
  ];

  # Minimal XDG directories
  xdg = {
    enable = true;
    
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Essential environment variables
  home.sessionVariables = {
    EDITOR = "nano";
    PAGER = "less";
  };

  # Minimal file management
  home.file = {
    ".vimrc".text = ''
      " Minimal vim configuration
      set nocompatible
      syntax on
      set number
      set tabstop=2
      set shiftwidth=2
      set expandtab
      set autoindent
    '';
  };
}