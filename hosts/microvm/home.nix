{ pkgs, ... }:

{
  # Minimal Home Manager configuration for MicroVM

  # Basic user info
  home = {
    username = "micro";
    homeDirectory = "/home/micro";
    stateVersion = "25.05";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Minimal shell configuration
  programs.bash = {
    enable = true;

    shellAliases = {
      # Essential aliases only
      ll = "ls -l";
      la = "ls -la";

      # System info
      "sys" = "echo 'MicroVM:' $(hostname) '|' $(uname -r) '|' $(free -h | grep Mem | awk '{print $3\"/\"$2}')";
      "ip" = "ip -c addr show";

      # Quick navigation
      ".." = "cd ..";
    };

    bashrcExtra = ''
      # Ultra-minimal prompt
      export PS1="μvm:\w\$ "
      
      # Show system info on login (minimal)
      echo "μVM: $(hostname) [$(free -h | grep Mem | awk '{print $3}') used]"
    '';
  };

  # Minimal essential programs
  programs = {
    # Basic file operations
    ls = {
      enable = true;
      aliases = {
        l = "ls";
        ll = "ls -l";
      };
    };
  };

  # Minimal packages (only absolute essentials)
  home.packages = with pkgs; [
    # System utilities
    procps # ps, top, etc.

    # Network tools
    iproute2 # ip command
    iputils # ping

    # File utilities  
    file
    which
  ];

  # Minimal environment
  home.sessionVariables = {
    EDITOR = "nano";
    PAGER = "cat";

    # MicroVM identification
    MICROVM = "true";
    VM_TYPE = "microvm";
  };

  # No GUI applications
  # No development tools 
  # No extras - keep it ultra-minimal

  # Essential directories only
  xdg = {
    enable = true;
    userDirs = {
      enable = false; # Don't create extra directories
    };
  };
}
