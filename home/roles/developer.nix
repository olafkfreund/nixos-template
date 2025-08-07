# Developer Role Configuration
# Complete development environment setup
{ ... }:

{
  imports = [
    ../common/base.nix
    ../common/git.nix
    ../common/packages/essential.nix
    ../common/packages/development.nix
    ../common/packages/desktop.nix
  ];

  # Developer-specific programs
  programs = {
    # Advanced shell with better history and completion
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      
      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        share = true;
      };
      
      shellAliases = {
        # Development shortcuts
        gs = "git status";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";
        gd = "git diff";
        
        # Docker shortcuts
        dc = "docker-compose";
        dcu = "docker-compose up";
        dcd = "docker-compose down";
        dcl = "docker-compose logs";
        
        # Directory shortcuts
        dev = "cd ~/Development";
        proj = "cd ~/Projects";
      };
    };

    # Direnv for project environments
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    # Starship prompt
    starship = {
      enable = true;
      
      settings = {
        add_newline = false;
        
        format = "$all$character";
        
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        
        git_branch = {
          format = "[$symbol$branch]($style) ";
        };
        
        git_status = {
          format = "([$all_status$ahead_behind]($style) )";
        };
      };
    };

    # Better cat with syntax highlighting
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        style = "numbers,changes,header";
      };
    };

    # Fuzzy finder
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  # Development-specific XDG directories
  xdg.userDirs = {
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    desktop = "$HOME/Desktop";
    
    # Development directories
    extraConfig = {
      XDG_DEV_DIR = "$HOME/Development";
      XDG_PROJECTS_DIR = "$HOME/Projects";
    };
  };
}