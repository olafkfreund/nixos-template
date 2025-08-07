# Example: Gamer KDE Home Configuration
# This shows a gaming setup with KDE
{ ... }:

{
  # Import role and profile
  imports = [
    ../roles/gamer.nix # Gaming tools and environment
    ../profiles/kde.nix # KDE desktop environment
  ];

  # User-specific information
  home = {
    username = "gamer";
    homeDirectory = "/home/gamer";
  };

  # User-specific git configuration
  programs.git = {
    userName = "Epic Gamer";
    userEmail = "gamer@gaming.com";
  };

  # Gaming-specific overrides
  programs.zsh = {
    shellAliases = {
      # Game-specific shortcuts
      wow = "lutris lutris:rungameid/1";
      steam-proton = "PROTON_USE_WINED3D=1 steam";

      # Streaming shortcuts
      stream-setup = "obs-studio & discord &";

      # Performance shortcuts
      gaming-mode = "sudo cpupower frequency-set -g performance";
      power-save = "sudo cpupower frequency-set -g powersave";
    };
  };

  # Gaming-specific MangoHud overrides
  programs.mangohud.settings = {
    # Customize for this specific gaming setup
    position = "top-right"; # Different position than default
    fps_limit = 144; # Match monitor refresh rate

    # Add custom metrics for this gaming rig
    gpu_core_clock = true;
    gpu_mem_clock = true;
    gpu_power = true;
  };
}
