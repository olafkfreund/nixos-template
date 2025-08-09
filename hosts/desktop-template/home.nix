# Desktop Template Home Manager Configuration
# Uses shared profiles to reduce duplication
{ config, pkgs, ... }:

{
  # Import shared Home Manager profiles
  imports = [
    ../../home/profiles/base.nix # Base configuration with git, bash, etc.
    ../../home/profiles/desktop.nix # Desktop applications and GUI tools
    ../../home/profiles/development.nix # Development tools and environments
  ];

  # Host-specific user info (overrides base profile defaults)
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  # Override git configuration with host-specific details
  programs.git = {
    userName = "Desktop User";
    userEmail = "user@example.com";
  };

  # Desktop template-specific customizations
  home.sessionVariables = {
    # Override base profile editor for desktop development
    EDITOR = "code";
    BROWSER = "firefox";
    TERMINAL = "gnome-terminal";

    # Development optimizations
    NODE_OPTIONS = "--max-old-space-size=8192";

    # Graphics/Wayland support
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
  };

  # Desktop-specific additional packages (extends profile packages)
  home.packages = with pkgs; [
    # Advanced development tools (beyond development profile)
    jetbrains.idea-community
    dbeaver-bin
    postman

    # Creative applications (beyond desktop profile)
    blender
    audacity
    obs-studio
    krita
    darktable

    # Additional communication tools
    signal-desktop
    slack

    # Gaming tools (beyond desktop profile)
    lutris
    heroic
    steam-run

    # Cloud and sync tools
    rclone
    syncthing
  ];

  # Enhanced bash configuration for desktop development
  programs.bash.shellAliases = {
    # Development shortcuts (extends base profile aliases)
    "serve" = "python -m http.server 8000";
    "json" = "python -m json.tool";

    # Docker shortcuts
    "dps" = "docker ps";
    "dpa" = "docker ps -a";
    "di" = "docker images";
    "dex" = "docker exec -it";

    # Desktop integration
    "open" = "xdg-open";
    "pbcopy" = "xclip -selection clipboard";
    "pbpaste" = "xclip -selection clipboard -o";
  };

  # Desktop-specific bash enhancements
  programs.bash.bashrcExtra = ''
    # Development aliases for desktop
    alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'

    # Quick project navigation
    cdp() {
      if [ -d "$HOME/Projects/$1" ]; then
        cd "$HOME/Projects/$1"
      else
        echo "Project $1 not found in ~/Projects/"
      fi
    }
  '';
}
