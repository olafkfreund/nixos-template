# Gamer Role Configuration
# Gaming-focused setup with performance monitoring and game launchers
{ pkgs, ... }:

{
  imports = [
    ../common/base.nix
    ../common/git.nix
    ../common/packages/essential.nix
    ../common/packages/desktop.nix
  ];

  # Gaming-specific packages
  home.packages = with pkgs; [
    # Game Launchers and Management
    steam             # Steam gaming platform
    lutris            # Game launcher for various platforms
    heroic            # Epic/GOG launcher
    bottles           # Windows app compatibility
    
    # Performance Monitoring
    mangohud          # Gaming performance overlay
    goverlay          # MangoHud GUI configurator
    corectrl          # GPU/CPU control center
    
    # Graphics and Drivers
    mesa-demos        # OpenGL demos and tests
    vulkan-tools      # Vulkan utilities
    clinfo            # OpenCL information
    
    # Communication
    discord           # Gaming communication
    
    # Game Development (optional)
    # godot_4         # Game engine
    # blender         # 3D modeling
    
    # Streaming and Recording
    obs-studio        # Streaming/recording software
    kdenlive          # Video editing
    
    # Emulation
    # retroarch       # Multi-system emulator
    # duckstation     # PlayStation emulator
    # pcsx2           # PlayStation 2 emulator
    # dolphin-emu     # GameCube/Wii emulator
    
    # Audio
    pavucontrol       # Audio control
    easyeffects       # Audio effects
    
    # File Management for Games
    p7zip             # 7z archive support
    unrar             # RAR archive support
  ];

  # Gaming-optimized programs
  programs = {
    # Bash with gaming shortcuts
    bash = {
      shellAliases = {
        # Steam shortcuts
        steam-native = "steam -native";
        steam-bigpicture = "steam -bigpicture";
        
        # Performance monitoring
        gpu-info = "glxinfo | grep -E '(OpenGL vendor|OpenGL renderer|OpenGL version)'";
        vulkan-info = "vulkaninfo | head -20";
        
        # Game directories
        games = "cd ~/Games";
        steam-games = "cd ~/.steam/steam/steamapps/common";
        
        # System performance
        temps = "watch -n 2 sensors";
        perf = "htop --sort-key PERCENT_CPU";
      };
    };

    # Gaming-focused shell with better autocomplete
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      
      shellAliases = {
        # Game management
        lutris-debug = "lutris -d";
        steam-logs = "tail -f ~/.steam/logs/stderr.txt";
        
        # Wine/Proton
        winecfg = "winecfg";
        winetricks = "winetricks";
        
        # Performance
        cpu-freq = "watch -n 1 'cat /proc/cpuinfo | grep MHz'";
        gpu-temp = "nvidia-smi -q -d temperature";
      };
    };

    # MangoHud configuration
    mangohud = {
      enable = true;
      settings = {
        # Performance metrics to show
        fps = true;
        frametime = true;
        cpu_temp = true;
        gpu_temp = true;
        cpu_load_change = true;
        gpu_load_change = true;
        ram = true;
        vram = true;
        
        # Display settings
        position = "top-left";
        font_size = 24;
        alpha = 0.8;
        
        # Logging
        output_folder = "~/Documents/mangohud-logs";
        log_duration = 30;
      };
    };
  };

  # XDG directories for gaming
  xdg.userDirs = {
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    desktop = "$HOME/Desktop";
    videos = "$HOME/Videos";  # For recordings
    
    # Gaming-specific directories
    extraConfig = {
      XDG_GAMES_DIR = "$HOME/Games";
      XDG_ROMS_DIR = "$HOME/Games/ROMs";
      XDG_SAVES_DIR = "$HOME/Games/Saves";
    };
  };

  # Gaming-specific services
  services = {
    # Game mode for performance optimization
    gamemoded.enable = true;
  };
}