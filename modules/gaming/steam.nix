{ config, lib, pkgs, ... }:

with lib;
with lib.attrsets;

let
  cfg = config.modules.gaming.steam;
in
{
  options.modules.gaming.steam = {
    enable = mkEnableOption "Steam gaming platform with optimizations";

    package = mkOption {
      type = types.package;
      default = pkgs.steam;
      description = "Steam package to use";
    };

    remotePlay = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam Remote Play functionality";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall ports for Steam Remote Play";
      };
    };

    localNetworkGameTransfers = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Steam Local Network Game Transfers";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall ports for Local Network Game Transfers";
      };
    };

    gamescopeSession = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable gamescope session for Steam Big Picture mode";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional arguments to pass to gamescope";
        example = [ "--rt" "--prefer-vk-device" "8086:9bc4" ];
      };
    };

    compattools = {
      proton-ge = mkOption {
        type = types.bool;
        default = true;
        description = "Install Proton-GE for better game compatibility";
      };

      luxtorpeda = mkOption {
        type = types.bool;
        default = false;
        description = "Install Luxtorpeda for native Linux game engines";
      };
    };

    hardware = {
      steam-hardware = mkOption {
        type = types.bool;
        default = true;
        description = "Enable support for Steam hardware (Steam Deck, Index, etc.)";
      };
    };

    fonts = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install additional fonts for better game compatibility";
      };
    };

    performance = {
      gamemode = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GameMode for performance optimization";
      };

      mangohud = mkOption {
        type = types.bool;
        default = true;
        description = "Enable MangoHud for performance overlay";
      };

      optimizations = mkOption {
        type = types.bool;
        default = true;
        description = "Apply system optimizations for gaming";
      };
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional packages to install for Steam gaming";
      example = literalExpression ''
        with pkgs; [
          protontricks
          steamtinkerlaunch
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    # Assertions
    assertions = [
      {
        assertion = cfg.gamescopeSession.enable -> config.services.xserver.enable || config.programs.wayland.enable or false;
        message = "GameScope session requires either X11 or Wayland to be enabled";
      }
    ];

    # Enable Steam
    programs.steam = {
      enable = true;
      package = cfg.package;
    } // (optionalAttrs cfg.gamescopeSession.enable {
      gamescopeSession = {
        enable = true;
        args = cfg.gamescopeSession.args;
      };
    });

    # Hardware support
    hardware.steam-hardware.enable = mkIf cfg.hardware.steam-hardware cfg.hardware.steam-hardware;

    # Steam firewall ports (if needed, configure per host)
    # networking.firewall = {
    #   allowedTCPPorts = [ 27036 ];
    #   allowedUDPPorts = [ 27031 27036 ];
    #   allowedTCPPortRanges = [
    #     { from = 27015; to = 27030; }
    #   ];
    #   allowedUDPPortRanges = [
    #     { from = 27000; to = 27100; }
    #   ];
    # };

    # Performance optimization
    programs.gamemode = mkIf cfg.performance.gamemode {
      enable = true;
      settings = {
        general = {
          renice = 10;
          ioprio = 7;
          inhibit_screensaver = 1;
          softrealtime = "auto";
        };

        filter = {
          whitelist = "steam";
        };

        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          amd_performance_level = "high";
        };

        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode activated' 'System optimized for gaming'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode deactivated' 'System back to normal'";
        };
      };
    };

    # System packages for gaming
    environment.systemPackages = with pkgs; [
      # Core Steam and gaming tools
      cfg.package

      # Performance monitoring and optimization
      (mkIf cfg.performance.mangohud mangohud)
      (mkIf cfg.performance.gamemode gamemode)

      # Proton and compatibility tools
      # Note: proton-ge-bin should be managed through protonup-qt or Steam directly
      # (mkIf cfg.compattools.proton-ge proton-ge-bin)
      # Note: luxtorpeda is not available as standalone package in nixpkgs
      # It can be managed through protonup-qt or installed manually
      # (mkIf cfg.compattools.luxtorpeda luxtorpeda)
      protontricks

      # Gaming utilities
      steamtinkerlaunch
      steam-run

      # Audio support
      pulseaudio
      pavucontrol

      # Input device support
      linuxConsoleTools
      jstest-gtk

      # Wine for additional Windows game support
      wine
      winetricks

      # Additional gaming fonts
      (mkIf cfg.fonts.enable liberation_ttf)
      (mkIf cfg.fonts.enable dejavu_fonts)
      (mkIf cfg.fonts.enable source-han-sans)
      (mkIf cfg.fonts.enable wqy_zenhei)

      # Extra packages specified by user
    ] ++ cfg.extraPackages;

    # Gaming optimizations
    boot = mkIf cfg.performance.optimizations {
      # Kernel parameters for gaming
      kernelParams = [
        # CPU scheduling optimizations
        "preempt=full"
        "threadirqs"

        # Memory management
        "transparent_hugepage=madvise"

        # Reduce audio latency
        "snd_hda_intel.power_save=0"
      ];

      # Use latest kernel for better hardware support
      kernelPackages = mkDefault pkgs.linuxPackages_latest;

      # Kernel modules for gaming hardware
      kernelModules = [
        "uinput" # For Steam Controller and input remapping
        "snd-seq" # For MIDI support in games
        "snd-rawmidi" # For raw MIDI support
      ];
    };

    # System configuration optimizations
    systemd = mkIf cfg.performance.optimizations {
      # Disable unnecessary services during gaming
      services = {
        # Disable power management that might interfere with gaming
        power-profiles-daemon.enable = mkForce false;

        # Configure user slice for better gaming performance
        "user@".serviceConfig = {
          CPUWeight = 100;
          IOWeight = 100;
          MemoryHigh = "75%";
          TasksMax = 12288;
        };

        # System-wide gaming optimizations service
        steam-system-optimizations = {
          description = "System-wide Steam gaming optimizations";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "steam-system-optimize" ''
              # System-wide gaming optimizations
              echo 'Applying system-wide gaming optimizations...'
              
              # Increase file descriptor limits
              echo '* soft nofile 1048576' >> /etc/security/limits.conf
              echo '* hard nofile 1048576' >> /etc/security/limits.conf
              
              # Note: vm.max_map_count and vm.swappiness are now configured 
              # declaratively in the gaming preset module
            '';
          };
        };
      };

      # Gaming-specific tmpfiles
      tmpfiles.rules = [
        # Create Steam runtime directory with proper permissions
        "d /tmp/.X11-unix 1777 root root -"

        # Ensure proper permissions for audio
        "d /dev/snd 0755 root audio -"

        # Create directory for MangoHud configs
        "d /etc/mangohud 0755 root root -"
      ];

      # User services for gaming optimizations
      user.services = {
        # Steam optimization service
        steam-optimization = {
          description = "Steam Gaming Optimizations";
          wantedBy = [ "default.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "steam-optimize" ''
              # Set CPU governor to performance when Steam is running
              echo 'Applying Steam optimizations...'
              
              # Disable CPU power management
              echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
              
              # Set I/O scheduler to mq-deadline for better gaming performance
              for dev in /sys/block/sd*/queue/scheduler; do
                if [ -w "$dev" ]; then
                  echo mq-deadline > "$dev" 2>/dev/null || true
                fi
              done
              
              # Increase vm.max_map_count for memory-intensive games
              sysctl -w vm.max_map_count=2147483642 2>/dev/null || true
            '';
          };
        };
      };
    };

    # Security and permissions
    security = {
      # Allow games to use realtime scheduling
      rtkit.enable = mkDefault true;

      # Gaming-related PAM limits
      pam.loginLimits = mkIf cfg.performance.optimizations [
        {
          domain = "@games";
          type = "soft";
          item = "rtprio";
          value = "99";
        }
        {
          domain = "@games";
          type = "hard";
          item = "rtprio";
          value = "99";
        }
        {
          domain = "@games";
          type = "soft";
          item = "nice";
          value = "-20";
        }
        {
          domain = "@games";
          type = "hard";
          item = "nice";
          value = "-20";
        }
      ];
    };

    # Audio configuration for gaming
    services.pipewire = mkIf config.services.pipewire.enable {
      # Low-latency audio configuration for gaming
      extraConfig.pipewire."99-gaming-tweaks" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 32;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
        };
      };
    };

    # PulseAudio configuration (if not using PipeWire)
    services.pulseaudio = mkIf (config.services.pulseaudio.enable or false) {
      extraConfig = ''
        # Gaming audio optimizations
        load-module module-udev-detect tsched=0
        load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket
      '';
    };

    # Fonts for better game compatibility
    fonts = mkIf cfg.fonts.enable {
      packages = with pkgs; [
        liberation_ttf
        dejavu_fonts
        source-han-sans
        source-han-serif
        wqy_zenhei
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
      ];

      fontconfig = {
        enable = true;
        antialias = true;
        hinting.enable = true;
        hinting.style = "full";
        subpixel.rgba = "rgb";

        defaultFonts = {
          serif = [ "Liberation Serif" "DejaVu Serif" ];
          sansSerif = [ "Liberation Sans" "DejaVu Sans" ];
          monospace = [ "Liberation Mono" "DejaVu Sans Mono" ];
        };
      };
    };

    # Udev rules for gaming hardware
    services.udev.extraRules = ''
      # Steam Controller
      SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
      KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
      
      # Steam Deck in bootloader/fastboot mode
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0407", MODE="0666"
      
      # Valve generic HID devices
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="28de", MODE="0666"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
      
      # Nintendo Switch Pro Controller
      SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666"
      SUBSYSTEM=="hidraw", KERNELS=="*057E:2009*", MODE="0666"
      
      # Sony DualShock 4
      SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
      
      # Sony DualSense (PS5)
      SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0666"
      SUBSYSTEM=="hidraw", KERNELS=="*054C:0CE6*", MODE="0666"
      
      # Xbox controllers
      SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", MODE="0666"
      SUBSYSTEM=="hidraw", KERNELS=="*045E:*", MODE="0666"
    '';

    # Create steam user group
    users.groups.steam = { };

    # Environment variables for Steam and gaming
    environment.sessionVariables = {
      # Steam optimizations
      STEAM_RUNTIME_PREFER_HOST_LIBRARIES = "0";

      # Proton optimizations
      PROTON_USE_WINED3D = "0";
      PROTON_NO_ESYNC = "0";
      PROTON_NO_FSYNC = "0";
      PROTON_ENABLE_NVAPI = "1";

      # DXVK optimizations
      DXVK_LOG_LEVEL = "none";
      DXVK_CONFIG_FILE = "/etc/dxvk.conf";

      # VKD3D optimizations
      VKD3D_CONFIG = "dxr";

      # MangoHud
      MANGOHUD = mkIf cfg.performance.mangohud "1";
      MANGOHUD_CONFIGFILE = "/etc/mangohud/MangoHud.conf";

      # Gaming-specific OpenGL optimizations
      __GL_THREADED_OPTIMIZATIONS = "1";
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";

      # Vulkan optimizations
      VK_ICD_FILENAMES = "/usr/share/vulkan/icd.d/nvidia_icd.json:/usr/share/vulkan/icd.d/intel_icd.x86_64.json:/usr/share/vulkan/icd.d/radeon_icd.x86_64.json";

      # Wine optimizations
      WINEPREFIX = "$HOME/.wine";
      WINEARCH = "win64";
      WINE_CPU_TOPOLOGY = "4:2";
    };

    # DXVK configuration
    environment.etc."dxvk.conf".text = ''
      # DXVK configuration for gaming optimization
      
      # Enable State Cache
      dxvk.enableStateCache = True
      
      # GPU selection (auto-detect)
      dxvk.gpuSelection = 0
      
      # Memory allocation
      dxvk.maxFrameLatency = 1
      dxvk.numCompilerThreads = 0
      
      # Shader compilation
      dxvk.useRawSsbo = True
      
      # D3D11 specific
      d3d11.constantBufferRangeCheck = False
      d3d11.relaxedBarriers = True
      d3d11.maxTessFactor = 64
    '';

    # MangoHud configuration
    environment.etc."mangohud/MangoHud.conf" = mkIf cfg.performance.mangohud {
      text = ''
        # MangoHud configuration for gaming
        
        # Display settings
        position=top-left
        width=350
        height=140
        background_alpha=0.4
        font_size=24
        
        # Performance metrics
        fps
        frametime=0
        frame_count=0
        cpu_stats
        cpu_temp
        gpu_stats
        gpu_temp
        ram
        vram
        
        # Controls
        toggle_hud=Shift_R+F12
        toggle_logging=Shift_L+F2
        reload_cfg=Shift_L+F4
        
        # Logging
        output_folder=$HOME/Documents/mangohud-logs
        log_duration=60
        autostart_log=0
        
        # Performance limits (optional)
        fps_limit=0,60,120,144,165,240
        vsync=0
        gl_vsync=-1
        
        # Additional info
        wine
        gamemode
        vkbasalt
        
        # Filtering
        blacklist=
      '';
    };

    # Additional system tweaks for gaming performance
    services.irqbalance = mkIf cfg.performance.optimizations {
      enable = true;
    };


  };
}
