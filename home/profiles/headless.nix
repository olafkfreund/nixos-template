# Headless Profile Configuration
# Configuration for systems without graphical interface
{ lib, ... }:

{
  # Disable all GUI-related programs
  programs = {
    # Disable GUI applications that might be enabled by roles
    firefox.enable = lib.mkForce false;

    # Focus on terminal-based tools
    bash = {
      enable = true;

      shellAliases = {
        # System information aliases useful for headless
        sysinfo = "uname -a && uptime && free -h && df -h";
        netinfo = "ip addr show && ss -tuln";
        procinfo = "ps aux --sort=-%cpu | head -10";
      };
    };
  };

  # Ensure no GUI packages are installed
  home.packages = [ ];

  # Minimal XDG configuration for headless
  xdg = {
    enable = true;

    # Don't create desktop-related directories
    userDirs = {
      enable = true;
      createDirectories = lib.mkForce false;
      desktop = null;
      pictures = null;
      videos = null;
      music = null;
      publicShare = null;
      templates = null;
    };
  };

  # Terminal-focused configurations
  programs = {
    # Enhanced terminal experience
    tmux = {
      enable = lib.mkDefault true;
    };

    # Better terminal tools
    htop = {
      enable = true;
      settings = {
        show_cpu_frequency = true;
        show_cpu_temperature = true;
        tree_view = true;
      };
    };
  };
}
