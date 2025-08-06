{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    # Hardware configuration (generate with nixos-generate-config)
    ./hardware-configuration.nix
    
    # Desktop modules
    ../../modules/desktop
    ../../modules/development
    
    # Hardware support
    ../../modules/hardware
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Hostname
  networking.hostName = "example-desktop";

  # Enable desktop modules
  modules = {
    desktop = {
      # Choose your desktop environment (enable only one)
      
      # GNOME Desktop (default)
      gnome.enable = true;
      
      # KDE Plasma Desktop
      # kde = {
      #   enable = true;
      #   version = "plasma6";        # plasma5 or plasma6
      #   applications.enable = true; # KDE app suite
      #   wayland.enable = true;      # Wayland support
      #   theme.darkMode = true;      # Dark theme
      # };
      
      # Hyprland Tiling Window Manager  
      # hyprland = {
      #   enable = true;
      #   waybar.enable = true;       # Status bar
      #   dunst.enable = true;        # Notifications
      #   theme = {
      #     colorScheme = "dark";     # dark, light, auto
      #     wallpaper = "/path/to/wallpaper.jpg";
      #   };
      #   applications = {
      #     terminal = "alacritty";   # Default terminal
      #     launcher = "wofi";        # App launcher
      #     browser = "firefox";      # Default browser
      #   };
      # };
      
      # Niri Scrollable Tiling Window Manager
      # niri = {
      #   enable = true;
      #   waybar.enable = true;       # Status bar
      #   dunst.enable = true;        # Notifications
      #   theme = {
      #     colorScheme = "dark";     # dark, light, auto
      #     wallpaper = "/path/to/wallpaper.jpg";
      #   };
      #   applications = {
      #     terminal = "alacritty";   # Default terminal
      #     launcher = "fuzzel";      # App launcher (fuzzel recommended for niri)
      #     browser = "firefox";      # Default browser
      #   };
      #   scrolling = {
      #     workspaces = true;        # Enable workspace scrolling
      #     columns = true;           # Enable column scrolling
      #   };
      # };
      
      # Common desktop modules
      audio.enable = true;
      fonts.enable = true;
      graphics.enable = true;
    };
    
    development = {
      git = {
        enable = true;
        userName = "Your Name";
        userEmail = "your.email@example.com";
      };
    };
    
    # GPU Configuration - Choose your GPU type
    hardware.gpu = {
      # Auto-detect GPUs (recommended)
      autoDetect = true;
      profile = "desktop";  # Options: desktop, gaming, ai-compute, server-compute
      
      # Manual GPU selection (uncomment the one you have)
      # AMD GPU
      # amd = {
      #   enable = true;
      #   model = "auto";  # auto, rdna3, rdna2, rdna1, vega, polaris
      #   gaming = {
      #     enable = true;
      #     vulkan = true;
      #   };
      # };
      
      # NVIDIA GPU  
      # nvidia = {
      #   enable = true;
      #   driver = "stable";  # stable, beta, production, open
      #   hardware.model = "auto";  # auto, rtx40, rtx30, rtx20, gtx16, gtx10
      #   gaming = {
      #     enable = true;
      #     gsync = true;
      #     rtx = true;  # Enable RTX features
      #     prime = {
      #       enable = true;  # For hybrid graphics (laptop)
      #       offload = true;
      #     };
      #   };
      # };
      
      # Intel integrated GPU
      # intel = {
      #   enable = true;
      #   generation = "auto";  # auto, arc, xe, iris-xe, iris-plus, uhd, hd
      #   desktop = {
      #     vaapi = true;
      #     vulkan = true;
      #   };
      # };
      
      # Multi-GPU setup (if you have multiple GPUs)
      # multiGpu = {
      #   enable = true;
      #   primary = "nvidia";  # Which GPU handles display: amd, nvidia, intel
      # };
    };
  };

  # Users
  users.users.user = {
    isNormalUser = true;
    description = "Desktop User";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" ];
    
    # Initial password (change after first login)
    initialPassword = "nixos";
  };
  
  # Home Manager configuration for the user
  home-manager.users.user = import ./home.nix;

  # Desktop-specific services
  services = {
    # Printing support
    printing.enable = true;
    
    # Bluetooth support  
    blueman.enable = true;
    
    # Location services
    geoclue2.enable = true;
    
    # Flatpak support (optional)
    flatpak.enable = lib.mkDefault false;
  };
  
  # Hardware support
  hardware = {
    # Bluetooth
    bluetooth.enable = true;
    
    # OpenGL/graphics
    graphics.enable = true;
    
    # Firmware
    enableRedistributableFirmware = true;
    
    # CPU microcode
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };

  # Power management
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  
  # TLP for laptop power management (disable for desktops)
  services.tlp = {
    enable = lib.mkDefault false;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # This value determines the NixOS release
  system.stateVersion = "25.05";
}