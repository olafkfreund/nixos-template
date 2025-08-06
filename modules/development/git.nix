{ config, lib, pkgs, ... }:

let
  cfg = config.modules.development.git;
in
{
  options.modules.development.git = {
    enable = lib.mkEnableOption "Git development tools";
    userName = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Global git user name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Global git user email";
    };
    signing = {
      enable = lib.mkEnableOption "Git commit signing";
      key = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "GPG key ID for commit signing";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      
      # Global configuration
      config = lib.mkMerge [
        # Basic configuration
        {
          user = lib.mkIf (cfg.userName != "" && cfg.userEmail != "") {
            name = cfg.userName;
            email = cfg.userEmail;
          };
          
          init.defaultBranch = "main";
          
          # Better diffs and merges
          diff.algorithm = "patience";
          merge.conflictstyle = "diff3";
          
          # Push configuration
          push.default = "simple";
          push.autoSetupRemote = true;
          
          # Pull configuration
          pull.rebase = true;
          
          # Color configuration
          color.ui = "auto";
          
          # Aliases
          alias = {
            st = "status -s";
            co = "checkout";
            br = "branch";
            ci = "commit";
            unstage = "reset HEAD --";
            last = "log -1 HEAD";
            visual = "!gitk";
            
            # Pretty log formats
            lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            ll = "log --oneline";
          };
        }
        
        # Signing configuration
        (lib.mkIf cfg.signing.enable {
          commit.gpgSign = true;
          tag.gpgSign = true;
          user.signingkey = cfg.signing.key;
        })
      ];
    };
    
    # Additional Git tools
    environment.systemPackages = with pkgs; [
      git-lfs        # Large file support
      gh             # GitHub CLI
      gitflow        # Git Flow extensions
      tig            # Text-based Git interface
      lazygit        # Terminal Git UI
      gitui          # Another terminal Git UI
    ];
    
    # GPG support for commit signing
    programs.gnupg.agent = lib.mkIf cfg.signing.enable {
      enable = true;
      enableSSHSupport = true;
    };
  };
}