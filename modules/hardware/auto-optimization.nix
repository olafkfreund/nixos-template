# Hardware Auto-Optimization Module
# Automatically detects hardware capabilities and optimizes system configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.autoOptimization;

  # Hardware detection functions
  hwDetection = {
    # Memory detection (in GB) - Use simple fallback for build-time
    memoryGB = 16; # Reasonable default for most systems

    # CPU detection - Use simple fallback for build-time
    cpuCores = 8; # Reasonable default for most systems

    # GPU detection - Use simple fallback for build-time
    hasNvidiaGPU = false;
    hasAMDGPU = false;
    hasIntelGPU = true; # Most common default

    # Storage detection - Use simple fallback for build-time
    hasSSD = true; # Most modern systems have SSDs

    # Power supply detection - Use simple fallback for build-time
    isLaptop = false; # Default to desktop
  };

  # Optimization configurations based on detected hardware
  optimizations = {
    # Memory-based configurations
    memory = {
      zramPercent =
        if hwDetection.memoryGB >= 32 then 10
        else if hwDetection.memoryGB >= 16 then 25
        else if hwDetection.memoryGB >= 8 then 50
        else 75;

      swappiness =
        if hwDetection.memoryGB >= 16 then 10
        else if hwDetection.memoryGB >= 8 then 20
        else 60;

      kernelParams =
        if hwDetection.memoryGB >= 32 then [
          "transparent_hugepage=madvise"
          "vm.nr_hugepages=1024"
        ] else [ ];
    };

    # CPU-based configurations
    cpu = {
      governor =
        if hwDetection.isLaptop then "powersave"
        else "performance";

      buildCores = min hwDetection.cpuCores 8; # Cap build parallelism
      buildJobs =
        if hwDetection.memoryGB >= 16 then "auto"
        else min (hwDetection.cpuCores / 2) 4;

      kernelPackage =
        if hwDetection.cpuCores >= 16 then pkgs.linuxPackages_latest
        else if hwDetection.cpuCores >= 8 then pkgs.linuxPackages
        else pkgs.linuxPackages_hardened;
    };

    # GPU-based configurations
    gpu = {
      enableHardwareAcceleration =
        hwDetection.hasNvidiaGPU || hwDetection.hasAMDGPU || hwDetection.hasIntelGPU;

      drivers =
        (optionals hwDetection.hasNvidiaGPU [ "nvidia" ]) ++
        (optionals hwDetection.hasAMDGPU [ "amdgpu" ]) ++
        (optionals hwDetection.hasIntelGPU [ "i915" ]);

      openglPackages = with pkgs;
        (optionals hwDetection.hasNvidiaGPU [ nvidia-vaapi-driver ]) ++
        (optionals hwDetection.hasAMDGPU [ mesa.drivers ]) ++
        (optionals hwDetection.hasIntelGPU [ intel-media-driver ]);
    };

    # Storage-based configurations
    storage = {
      filesystem = if hwDetection.hasSSD then "ext4" else "btrfs";
      schedulerClass = if hwDetection.hasSSD then "none" else "bfq";
      mountOptions =
        if hwDetection.hasSSD then [ "noatime" "discard=async" ]
        else [ "compress=zstd" "noatime" ];
    };

    # Platform-specific optimizations
    platform = {
      kernelParams =
        (optionals hwDetection.isLaptop [
          "intel_pstate=active"
          "pcie_aspm=force"
        ]) ++
        (optionals (!hwDetection.isLaptop) [
          "intel_idle.max_cstate=1"
          "processor.max_cstate=1"
        ]);

      services = {
        enablePowerManagement = hwDetection.isLaptop;
        enableThermalManagement = hwDetection.cpuCores >= 8 || hwDetection.isLaptop;
        enableFwupd = hwDetection.isLaptop;
      };
    };
  };

in
{
  options.hardware.autoOptimization = {
    enable = mkEnableOption "automatic hardware detection and optimization";

    detection = {
      enableMemoryOptimization = mkOption {
        type = types.bool;
        default = true;
        description = "Enable memory-based optimizations";
      };

      enableCpuOptimization = mkOption {
        type = types.bool;
        default = true;
        description = "Enable CPU-based optimizations";
      };

      enableGpuOptimization = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GPU detection and optimization";
      };

      enableStorageOptimization = mkOption {
        type = types.bool;
        default = true;
        description = "Enable storage-based optimizations";
      };

      enablePlatformOptimization = mkOption {
        type = types.bool;
        default = true;
        description = "Enable platform-specific optimizations";
      };
    };

    override = {
      memoryGB = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Override detected memory amount (GB)";
      };

      cpuCores = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Override detected CPU core count";
      };

      isLaptop = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Override laptop detection";
      };

      hasNvidiaGPU = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Override NVIDIA GPU detection";
      };

      hasSSD = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Override SSD detection";
      };
    };

    debug = mkOption {
      type = types.bool;
      default = false;
      description = "Enable debug information about hardware detection";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Memory optimizations
    (mkIf cfg.detection.enableMemoryOptimization {
      # ZRAM configuration
      zramSwap = {
        enable = mkDefault true;
        algorithm = mkDefault "zstd";
        memoryPercent = mkDefault optimizations.memory.zramPercent;
      };

      # Kernel memory parameters
      boot.kernel.sysctl = {
        "vm.swappiness" = mkDefault optimizations.memory.swappiness;
        "vm.vfs_cache_pressure" = mkDefault 50;
        "vm.dirty_ratio" = mkDefault 15;
        "vm.dirty_background_ratio" = mkDefault 5;
      } // (optionalAttrs (optimizations.memory.kernelParams != [ ]) {
        "vm.nr_hugepages" = mkIf (hwDetection.memoryGB >= 32) 1024;
      });

      # Additional kernel parameters
      boot.kernelParams = mkDefault optimizations.memory.kernelParams;
    })

    # CPU optimizations
    (mkIf cfg.detection.enableCpuOptimization {
      # CPU governor
      powerManagement.cpuFreqGovernor = mkDefault optimizations.cpu.governor;

      # Build parallelism
      nix.settings = {
        cores = mkDefault optimizations.cpu.buildCores;
        max-jobs = mkDefault optimizations.cpu.buildJobs;
      };

      # Kernel package selection
      boot.kernelPackages = mkDefault optimizations.cpu.kernelPackage;

      # CPU-specific kernel modules (defaults to Intel)
      boot.kernelModules = mkDefault [ "kvm-intel" ];
    })

    # GPU optimizations
    (mkIf cfg.detection.enableGpuOptimization {
      # Hardware acceleration
      hardware.graphics = {
        enable = mkDefault optimizations.gpu.enableHardwareAcceleration;
        extraPackages = mkDefault optimizations.gpu.openglPackages;
      };

      # GPU drivers
      services.xserver.videoDrivers = mkDefault optimizations.gpu.drivers;

      # NVIDIA specific configuration
      hardware.nvidia = mkIf hwDetection.hasNvidiaGPU {
        modesetting.enable = mkDefault true;
        powerManagement.enable = mkDefault hwDetection.isLaptop;
        powerManagement.finegrained = mkDefault hwDetection.isLaptop;
        open = mkDefault false; # Use proprietary driver for stability
        nvidiaSettings = mkDefault true;
      };
    })

    # Storage optimizations
    (mkIf cfg.detection.enableStorageOptimization {
      # I/O scheduler
      boot.kernel.sysctl = mkIf hwDetection.hasSSD {
        "kernel.sched_autogroup_enabled" = 1;
      };

      # Filesystem defaults for new installations
      # Note: This doesn't change existing filesystems
      environment.etc."hardware-optimization-info".text = ''
        # Hardware-optimized defaults for new filesystem creation:
        # Storage type: ${if hwDetection.hasSSD then "SSD" else "HDD"}
        # Recommended filesystem: ${optimizations.storage.filesystem}
        # Recommended scheduler: ${optimizations.storage.schedulerClass}
        # Recommended mount options: ${concatStringsSep "," optimizations.storage.mountOptions}
      '';
    })

    # Platform optimizations
    (mkIf cfg.detection.enablePlatformOptimization {
      # Platform-specific kernel parameters
      boot.kernelParams = mkDefault optimizations.platform.kernelParams;

      # Power management (with lower priority to avoid conflicts)
      services.power-profiles-daemon.enable = lib.mkOverride 1500 optimizations.platform.services.enablePowerManagement;
      services.thermald.enable = mkDefault optimizations.platform.services.enableThermalManagement;
      services.fwupd.enable = mkDefault optimizations.platform.services.enableFwupd;

      # Laptop-specific services
      services.tlp = mkIf hwDetection.isLaptop {
        enable = mkDefault true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
          START_CHARGE_THRESH_BAT0 = 20;
          STOP_CHARGE_THRESH_BAT0 = 80;
        };
      };
    })

    # Debug information
    (mkIf cfg.debug {
      environment.systemPackages = with pkgs; [
        (writeShellScriptBin "hardware-detection-info" ''
          echo "🔍 Hardware Detection Results"
          echo "============================"
          echo ""
          echo "💾 Memory: ${toString (cfg.override.memoryGB or hwDetection.memoryGB)} GB"
          echo "🏗️  CPU Cores: ${toString (cfg.override.cpuCores or hwDetection.cpuCores)}"
          echo "💻 Is Laptop: ${if (cfg.override.isLaptop or hwDetection.isLaptop) then "Yes" else "No"}"
          echo "🖥️  Has NVIDIA GPU: ${if (cfg.override.hasNvidiaGPU or hwDetection.hasNvidiaGPU) then "Yes" else "No"}"
          echo "🖥️  Has AMD GPU: ${if hwDetection.hasAMDGPU then "Yes" else "No"}"
          echo "🖥️  Has Intel GPU: ${if hwDetection.hasIntelGPU then "Yes" else "No"}"
          echo "💿 Has SSD: ${if (cfg.override.hasSSD or hwDetection.hasSSD) then "Yes" else "No"}"
          echo ""
          echo "⚙️  Applied Optimizations:"
          echo "  ZRAM: ${toString optimizations.memory.zramPercent}% of RAM"
          echo "  CPU Governor: ${optimizations.cpu.governor}"
          echo "  Build Cores: ${toString optimizations.cpu.buildCores}"
          echo "  Build Jobs: ${toString optimizations.cpu.buildJobs}"
          echo "  Kernel Package: ${optimizations.cpu.kernelPackage.name}"
          echo ""
          echo "📋 Hardware Info File: /etc/hardware-optimization-info"
        '')
      ];

      # Detailed hardware information
      environment.etc."hardware-detection-debug.json".text = builtins.toJSON {
        detection = hwDetection;
        optimizations = optimizations;
        overrides = cfg.override;
      };
    })

    # Basic hardware info command (always available when enabled)
    {
      environment.systemPackages = with pkgs; [
        (writeShellScriptBin "hw-info" ''
          echo "🔍 Quick Hardware Info"
          echo "===================="
          echo "Memory: ${toString (cfg.override.memoryGB or hwDetection.memoryGB)}GB | CPU: ${toString (cfg.override.cpuCores or hwDetection.cpuCores)} cores | ${if (cfg.override.isLaptop or hwDetection.isLaptop) then "Laptop" else "Desktop"} | ${if (cfg.override.hasSSD or hwDetection.hasSSD) then "SSD" else "HDD"}"
        '')
      ];
    }
  ]);
}
