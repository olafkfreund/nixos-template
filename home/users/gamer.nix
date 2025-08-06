{ config, lib, pkgs, inputs, outputs, ... }:

{
  # Gaming-focused Home Manager configuration
  
  # Import desktop profile (KDE or GNOME recommended for gaming)
  imports = [
    # Recommended for gaming
    ../profiles/kde.nix      # KDE has excellent gaming features
    # ../profiles/gnome.nix   # GNOME also works well
    # ../profiles/hyprland.nix  # Advanced users only
  ];
  
  # User information
  home = {
    username = "gamer";
    homeDirectory = "/home/gamer";
    stateVersion = "25.05";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Basic Git configuration
  programs.git = {
    enable = true;
    userName = "Gamer Name";
    userEmail = "gamer@example.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nano";
    };
  };

  # Gaming-optimized shell configuration
  programs.bash = {
    enable = true;
    
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # NixOS specific
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config";
      rebuild-test = "sudo nixos-rebuild test --flake ~/nixos-config";
      
      # Gaming shortcuts
      steam-native = "steam -native";
      steam-runtime = "steam";
      
      # System monitoring for gaming
      temps = "sensors";
      gpu-stats = "nvidia-smi";  # For NVIDIA users
      
      # Wine shortcuts
      winecfg = "winecfg";
      winetricks = "winetricks";
      
      # Proton shortcuts
      proton-log = "tail -f ~/.steam/steam/logs/content_log.txt";
    };
    
    bashrcExtra = ''
      # Gaming-focused prompt
      export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ "
      
      # Gaming environment variables
      export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0
      export DXVK_LOG_LEVEL=none
      export PROTON_USE_WINED3D=0
      export PROTON_NO_ESYNC=0
      export PROTON_NO_FSYNC=0
      
      # Performance optimizations
      export __GL_THREADED_OPTIMIZATIONS=1
      export __GL_SHADER_DISK_CACHE=1
      export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
    '';
  };

  # Gaming-focused programs
  programs = {
    # Enhanced command line tools
    eza = {
      enable = true;
      aliases = {
        ls = "eza";
        ll = "eza -l";
        la = "eza -la";
        tree = "eza --tree";
      };
    };
    
    bat.enable = true;
    fd.enable = true;
    ripgrep.enable = true;
    
    # System monitoring
    htop.enable = true;
    btop.enable = true;
    
    # Directory navigation
    zoxide.enable = true;
    
    # SSH (basic configuration)
    ssh = {
      enable = true;
      
      matchBlocks = {
        "game-server" = {
          hostname = "gameserver.example.com";
          user = "gamer";
          port = 22;
        };
      };
    };
  };

  # Gaming applications and tools
  home.packages = with pkgs; [
    # Gaming Platforms
    steam
    lutris
    heroic              # Epic Games launcher
    bottles             # Wine bottle manager
    
    # Game Development (optional)
    # godot_4
    # blender
    # aseprite
    
    # Wine and Windows Compatibility
    wine
    winetricks
    protontricks        # Proton management
    
    # Game Streaming
    moonlight-qt        # NVIDIA GameStream client
    parsec-bin          # Game streaming
    
    # Communication
    discord
    teamspeak_client
    mumble
    element-desktop     # Matrix client for gaming communities
    
    # Media and Entertainment
    vlc
    mpv
    spotify
    obs-studio          # Streaming and recording
    
    # System Tools
    htop
    btop
    nvtop               # GPU monitoring
    lm_sensors          # Temperature monitoring
    
    # File Management
    filelight           # Disk usage analyzer (KDE)
    # baobab            # Disk usage analyzer (GNOME)
    p7zip
    unrar
    
    # Network Tools
    speedtest-cli
    iperf3
    
    # Gaming Utilities
    gamemode            # Gaming performance optimization
    mangohud            # Gaming overlay
    goverlay            # MangoHud configuration GUI
    
    # Input Devices
    antimicrox          # Controller mapping
    # sc-controller     # Steam Controller support
    
    # Emulation (uncomment as needed)
    # retroarch
    # dolphin-emu       # GameCube/Wii
    # pcsx2             # PS2
    # rpcs3             # PS3
    # yuzu              # Nintendo Switch
    # citra             # Nintendo 3DS
    
    # System Information
    neofetch
    lshw
    pciutils
    usbutils
    
    # Web Browser
    firefox
    # chromium
    
    # Basic Tools
    file
    which
    tree
    curl
    wget
    git
  ];

  # Gaming-friendly XDG directories
  xdg = {
    enable = true;
    
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };
  };

  # Gaming environment variables
  home.sessionVariables = {
    EDITOR = "nano";
    BROWSER = "firefox";
    TERMINAL = "konsole";  # KDE terminal
    
    # Gaming optimizations
    STEAM_RUNTIME_PREFER_HOST_LIBRARIES = "0";
    DXVK_LOG_LEVEL = "none";
    PROTON_USE_WINED3D = "0";
    PROTON_NO_ESYNC = "0";
    PROTON_NO_FSYNC = "0";
    
    # Performance
    __GL_THREADED_OPTIMIZATIONS = "1";
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    
    # MangoHud
    MANGOHUD = "1";
    MANGOHUD_CONFIGFILE = "${config.xdg.configHome}/MangoHud/MangoHud.conf";
  };

  # Create gaming-specific directories and configs
  home.file = {
    "Games/.keep".text = "";
    "Emulation/.keep".text = "";
    "Screenshots/.keep".text = "";
    "Recordings/.keep".text = "";
    
    # MangoHud configuration
    ".config/MangoHud/MangoHud.conf".text = ''
      # MangoHud Configuration
      fps
      frametime=0
      cpu_stats
      gpu_stats
      cpu_temp
      gpu_temp
      ram
      vram
      position=top-left
      background_alpha=0.4
      font_size=24
      
      # Toggle key
      toggle_hud=Shift_R+F12
      toggle_logging=Shift_L+F2
      
      # Logging
      output_folder=${config.home.homeDirectory}/Recordings
      log_duration=60
    '';
    
    # GameMode configuration
    ".config/gamemode.ini".text = ''
      [general]
      renice=10
      ioprio=7
      
      [filter]
      whitelist=steam
      whitelist=lutris
      whitelist=heroic
      
      [gpu]
      apply_gpu_optimisations=accept-responsibility
      gpu_device=0
      amd_performance_level=high
      
      [custom]
      start=${pkgs.libnotify}/bin/notify-send "GameMode activated"
      end=${pkgs.libnotify}/bin/notify-send "GameMode deactivated"
    '';
  };

  # Gaming-specific services
  services = {
    # Flatpak for additional gaming applications
    flatpak.enable = lib.mkDefault true;
  };

  # Gaming-focused GTK theming (if using GTK apps)
  gtk = {
    enable = true;
    
    theme = {
      package = pkgs.adwaita-qt;
      name = "Adwaita-dark";
    };
    
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    
    cursorTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
      size = 24;
    };
    
    font = {
      name = "Inter";
      size = 11;
    };
    
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Qt theming (for KDE and Qt gaming applications)
  qt = {
    enable = true;
    platformTheme.name = "kde";
  };
}