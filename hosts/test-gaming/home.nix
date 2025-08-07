# test-gaming Home Configuration  
# Gaming setup with KDE desktop environment
{ ... }:

{
  imports = [
    ../../home/roles/gamer.nix       # Gaming tools and environment
    ../../home/profiles/kde.nix      # KDE desktop environment
  ];

  # User-specific information
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  # User-specific git configuration
  programs.git = {
    userName = "Test Gamer";
    userEmail = "gamer@test-gaming.local";
  };

  # Gaming-specific overrides
  programs.zsh = {
    shellAliases = {
      gaming-mode = "sudo cpupower frequency-set -g performance";
      temps = "watch -n 2 'sensors | grep -E \"(CPU|GPU)\"'";
      fps-test = "glxgears -info";
    };
  };

  # Custom MangoHud settings for this gaming rig
  programs.mangohud.settings = {
    position = "top-right";
    fps_limit = 60;  # Cap for this test system
  };
}
