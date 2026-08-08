# test-workstation Home Configuration
# Workstation setup with development tools and desktop environment
{ ... }:

{
  imports = [
    ../../home/roles/developer.nix # Development environment
    ../../home/profiles/gnome.nix # GNOME desktop
  ];

  # User-specific information
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  # User-specific git configuration
  programs.git = {
    settings.user.name = "Test User";
    settings.user.email = "test@workstation.local";
  };

  # Workstation-specific shell aliases
  programs.zsh = {
    shellAliases = {
      workstation-info = "fastfetch";
      dev-env = "cd ~/Development && code .";
    };
  };
}
