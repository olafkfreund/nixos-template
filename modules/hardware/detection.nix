# Advanced Hardware Detection and Optimization
# Automatically detects hardware characteristics and applies appropriate optimizations

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.hardware.detection;

  # Hardware detection functions
  detectVirtualization = 
    let
      # Check for common virtualization indicators
      hasQemuDmi = builtins.pathExists "/sys/class/dmi/id/product_name" &&
        lib.hasInfix "QEMU" (builtins.readFile "/sys/class/dmi/id/product_name" or "");
      hasVMwareeDmi = builtins.pathExists "/sys/class/dmi/id/sys_vendor" &&
        lib.hasInfix "VMware" (builtins.readFile "/sys/class/dmi/id/sys_vendor" or "");
      hasVirtualBoxDmi = builtins.pathExists "/sys/class/dmi/id/product_name" &&
        lib.hasInfix "VirtualBox" (builtins.readFile "/sys/class/dmi/id/product_name" or "");
      hasHyperVDmi = builtins.pathExists "/sys/class/dmi/id/sys_vendor" &&
        lib.hasInfix "Microsoft Corporation" (builtins.readFile "/sys/class/dmi/id/sys_vendor" or "");
      hasWSLInterop = builtins.pathExists "/proc/sys/fs/binfmt_misc/WSLInterop";
      hasDockerEnv = builtins.pathExists "/.dockerenv";
      hasContainerEnv = builtins.getEnv "container" != "";
    in {
      isVirtualMachine = hasQemuDmi || hasVMwareeDmi || hasVirtualBoxDmi || hasHyperVDmi;
      isWSL = hasWSLInterop;
      isContainer = hasDockerEnv || hasContainerEnv;
      virtualization = 
        if hasQemuDmi then "qemu"
        else if hasVMwareeDmi then "vmware" 
        else if hasVirtualBoxDmi then "virtualbox"
        else if hasHyperVDmi then "hyperv"
        else if hasWSLInterop then "wsl"
        else if hasContainerEnv then "container"
        else "bare-metal";
    };

  detectCPU = 
    let
      cpuinfo = if builtins.pathExists "/proc/cpuinfo" 
                then builtins.readFile "/proc/cpuinfo" 
                else "";
      
      # CPU vendor detection
      isIntel = lib.hasInfix "GenuineIntel" cpuinfo;
      isAMD = lib.hasInfix "AuthenticAMD" cpuinfo;
      isARM = lib.hasInfix "ARM" cpuinfo || builtins.currentSystem == "aarch64-linux";
      
      # CPU features detection
      hasAVX = lib.hasInfix " avx " cpuinfo;
      hasAVX2 = lib.hasInfix " avx2 " cpuinfo;
      hasAVX512 = lib.hasInfix " avx512" cpuinfo;
      hasSSE4 = lib.hasInfix " sse4" cpuinfo;
      hasAES = lib.hasInfix " aes " cpuinfo;
      
      # Core count detection
      coreCount = 
        let
          processorLines = builtins.filter (line: lib.hasPrefix "processor" line) 
                          (lib.splitString "\n" cpuinfo);
        in builtins.length processorLines;
        
      # CPU model detection
      modelName = 
        let
          modelLines = builtins.filter (line: lib.hasPrefix "model name" line)
                      (lib.splitString "\n" cpuinfo);
          firstModelLine = if modelLines != [] then builtins.head modelLines else "";
          modelMatch = builtins.match "model name[[:space:]]*:[[:space:]]*(.*)" firstModelLine;
        in if modelMatch != null then builtins.head modelMatch else "Unknown";
    in {
      vendor = if isIntel then "intel" 
               else if isAMD then "amd" 
               else if isARM then "arm"
               else "unknown";
      cores = coreCount;
      model = modelName;
      features = {
        inherit hasAVX hasAVX2 hasAVX512 hasSSE4 hasAES;
      };
    };

  detectMemory = 
    let
      meminfo = if builtins.pathExists "/proc/meminfo"
                then builtins.readFile "/proc/meminfo"
                else "";
      
      # Extract total memory in KB
      totalMemMatch = builtins.match ".*MemTotal:[[:space:]]*([0-9]+) kB.*" meminfo;
      totalMemKB = if totalMemMatch != null 
                   then lib.strings.toInt (builtins.head totalMemMatch)
                   else 0;
      
      # Convert to GB and classify
      totalMemGB = totalMemKB / 1024 / 1024;
      
      memoryClass = 
        if totalMemGB >= 32 then "high"
        else if totalMemGB >= 8 then "medium"
        else if totalMemGB >= 4 then "low"
        else "minimal";
    in {
      totalGB = totalMemGB;
      class = memoryClass;
    };

  detectStorage = 
    let
      # Detect if we're on SSD or HDD
      hasNVMe = builtins.pathExists "/sys/block" && 
                builtins.any (dev: lib.hasPrefix "nvme" dev) 
                (builtins.attrNames (builtins.readDir "/sys/block" or {}));
      
      hasSSD = builtins.pathExists "/sys/block" &&
               builtins.any (dev: 
                 let rotationalFile = "/sys/block/${dev}/queue/rotational";
                 in builtins.pathExists rotationalFile &&
                    builtins.readFile rotationalFile == "0\n"
               ) (builtins.attrNames (builtins.readDir "/sys/block" or {}));
    in {
      hasNVMe = hasNVMe;
      hasSSD = hasSSD || hasNVMe; # NVMe is always SSD
      primaryType = if hasNVMe then "nvme" 
                    else if hasSSD then "ssd" 
                    else "hdd";
    };

  detectGPU = 
    let
      # Check for GPU vendors
      hasNvidiaDevice = builtins.pathExists "/proc/driver/nvidia";
      hasAMDDevice = builtins.pathExists "/sys/class/drm" &&
                     builtins.any (dev: lib.hasInfix "amd" dev)
                     (builtins.attrNames (builtins.readDir "/sys/class/drm" or {}));
      hasIntelDevice = builtins.pathExists "/sys/class/drm" &&
                       builtins.any (dev: lib.hasInfix "intel" dev)
                       (builtins.attrNames (builtins.readDir "/sys/class/drm" or {}));
    in {
      hasNvidia = hasNvidiaDevice;
      hasAMD = hasAMDDevice;
      hasIntel = hasIntelDevice;
      hasDiscrete = hasNvidiaDevice || hasAMDDevice;
    };

  # Combine all detection results
  hardwareProfile = {
    virtualization = detectVirtualization;
    cpu = detectCPU;
    memory = detectMemory;
    storage = detectStorage;
    gpu = detectGPU;
  };

  # Performance profile determination
  performanceProfile = 
    let
      cpu = hardwareProfile.cpu;
      memory = hardwareProfile.memory;
      storage = hardwareProfile.storage;
    in
      if memory.class == "high" && cpu.cores >= 8 && storage.hasNVMe then "high-performance"
      else if memory.class == "medium" && cpu.cores >= 4 && storage.hasSSD then "balanced"
      else if memory.class == "low" then "resource-constrained"
      else "minimal";
in

{
  options.modules.hardware.detection = {
    enable = mkEnableOption "automatic hardware detection and optimization";

    autoOptimize = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically apply hardware-specific optimizations";
    };

    profile = mkOption {
      type = types.nullOr (types.enum [ "minimal" "resource-constrained" "balanced" "high-performance" ]);
      default = null;
      description = "Override automatic performance profile detection";
    };

    reporting = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable hardware detection reporting";
      };

      logLevel = mkOption {
        type = types.enum [ "info" "debug" ];
        default = "info";  
        description = "Hardware detection log level";
      };
    };

    overrides = {
      cpu = {
        vendor = mkOption {
          type = types.nullOr (types.enum [ "intel" "amd" "arm" ]);
          default = null;
          description = "Override CPU vendor detection";
        };

        cores = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Override CPU core count detection";
        };
      };

      virtualization = {
        type = mkOption {
          type = types.nullOr (types.enum [ "bare-metal" "qemu" "vmware" "virtualbox" "hyperv" "wsl" "container" ]);
          default = null;
          description = "Override virtualization detection";
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Hardware detection results and reporting
    {
      # Make hardware profile available to other modules
      _module.args.hardwareProfile = hardwareProfile // {
        performanceProfile = cfg.profile or performanceProfile;
        
        # Apply overrides
        cpu = hardwareProfile.cpu // {
          vendor = cfg.overrides.cpu.vendor or hardwareProfile.cpu.vendor;
          cores = cfg.overrides.cpu.cores or hardwareProfile.cpu.cores;
        };
        
        virtualization = hardwareProfile.virtualization // {
          virtualization = cfg.overrides.virtualization.type or hardwareProfile.virtualization.virtualization;
        };
      };

      # Hardware detection service for runtime reporting
      systemd.services.hardware-detection = mkIf cfg.reporting.enable {
        description = "Hardware Detection and Reporting";
        wantedBy = [ "multi-user.target" ];
        after = [ "basic.target" ];
        
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "hardware-detection" ''
            echo "=== Hardware Detection Report ===" | systemd-cat -t hardware-detection -p info
            echo "CPU: ${hardwareProfile.cpu.vendor} ${hardwareProfile.cpu.model} (${toString hardwareProfile.cpu.cores} cores)" | systemd-cat -t hardware-detection -p info
            echo "Memory: ${toString hardwareProfile.memory.totalGB}GB (${hardwareProfile.memory.class})" | systemd-cat -t hardware-detection -p info
            echo "Storage: ${hardwareProfile.storage.primaryType}" | systemd-cat -t hardware-detection -p info
            echo "Virtualization: ${hardwareProfile.virtualization.virtualization}" | systemd-cat -t hardware-detection -p info
            echo "Performance Profile: ${cfg.profile or performanceProfile}" | systemd-cat -t hardware-detection -p info
            
            ${optionalString (cfg.reporting.logLevel == "debug") ''
            echo "=== Debug Information ===" | systemd-cat -t hardware-detection -p debug
            echo "CPU Features: AVX=${toString hardwareProfile.cpu.features.hasAVX} AVX2=${toString hardwareProfile.cpu.features.hasAVX2} AES=${toString hardwareProfile.cpu.features.hasAES}" | systemd-cat -t hardware-detection -p debug
            echo "GPU: NVIDIA=${toString hardwareProfile.gpu.hasNvidia} AMD=${toString hardwareProfile.gpu.hasAMD} Intel=${toString hardwareProfile.gpu.hasIntel}" | systemd-cat -t hardware-detection -p debug
            echo "Storage: NVMe=${toString hardwareProfile.storage.hasNVMe} SSD=${toString hardwareProfile.storage.hasSSD}" | systemd-cat -t hardware-detection -p debug
            ''}
          '';
        };
      };

      # Environment variables for other services
      environment.variables = {
        NIXOS_HARDWARE_PROFILE = cfg.profile or performanceProfile;
        NIXOS_CPU_VENDOR = hardwareProfile.cpu.vendor;
        NIXOS_VIRTUALIZATION = hardwareProfile.virtualization.virtualization;
      };
    }

    # CPU-specific optimizations
    (mkIf (cfg.autoOptimize && hardwareProfile.cpu.vendor == "intel") {
      # Intel microcode updates
      hardware.cpu.intel.updateMicrocode = true;
      
      # Intel-specific kernel parameters
      boot.kernelParams = [
        "intel_pstate=active"
      ] ++ optionals hardwareProfile.cpu.features.hasAES [
        "cryptomgr.notests" # Skip crypto self-tests on Intel AES-NI
      ];
      
      # Intel graphics support
      hardware.graphics = mkIf hardwareProfile.gpu.hasIntel {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    })

    (mkIf (cfg.autoOptimize && hardwareProfile.cpu.vendor == "amd") {
      # AMD microcode updates  
      hardware.cpu.amd.updateMicrocode = true;
      
      # AMD-specific kernel parameters
      boot.kernelParams = [
        "amd_pstate=active"
      ];
      
      # AMD graphics support
      hardware.graphics = mkIf hardwareProfile.gpu.hasAMD {
        enable = true;
        extraPackages = with pkgs; [
          amdvlk
          rocm-opencl-icd
          rocm-opencl-runtime
        ];
        extraPackages32 = with pkgs.driversi686Linux; [
          amdvlk
        ];
      };
    })

    # Memory-based optimizations
    (mkIf (cfg.autoOptimize && hardwareProfile.memory.class == "minimal") {
      # Aggressive memory optimization for low-memory systems
      boot.kernel.sysctl = {
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_background_ratio" = 5;
        "vm.dirty_ratio" = 10;
      };

      # Disable memory-intensive features
      services.gnome.tracker.enable = false;
      services.gnome.tracker-miners.enable = false;
    })

    (mkIf (cfg.autoOptimize && hardwareProfile.memory.class == "high") {
      # High-memory optimizations
      boot.kernel.sysctl = {
        "vm.swappiness" = 1;
        "vm.vfs_cache_pressure" = 200;
        "vm.dirty_background_ratio" = 10;
        "vm.dirty_ratio" = 20;
      };

      # Enable transparent hugepages
      boot.kernelParams = [ "transparent_hugepage=always" ];
    })

    # Storage-based optimizations
    (mkIf (cfg.autoOptimize && hardwareProfile.storage.hasNVMe) {
      # NVMe optimizations
      boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];
      
      # I/O scheduler optimization for NVMe
      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
      '';
    })

    (mkIf (cfg.autoOptimize && hardwareProfile.storage.hasSSD && !hardwareProfile.storage.hasNVMe) {
      # SSD optimizations
      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      '';
    })

    # Virtualization-specific optimizations
    (mkIf (cfg.autoOptimize && hardwareProfile.virtualization.isVirtualMachine) {
      # VM guest optimizations
      services.qemuGuest.enable = mkDefault true;
      services.spice-vdagentd.enable = mkDefault true;
      
      # VM-specific kernel modules
      boot.kernelModules = [ 
        "virtio_net" "virtio_pci" "virtio_mmio" 
        "virtio_blk" "virtio_scsi" "virtio_console" 
      ];
      
      # Disable unnecessary services in VMs
      services.smartd.enable = false;
      powerManagement.enable = false;
      
      # VM-optimized scheduler
      boot.kernelParams = [ "elevator=noop" ];
    })

    (mkIf (cfg.autoOptimize && hardwareProfile.virtualization.isWSL) {
      # WSL-specific optimizations (reference existing WSL module)
      modules.wsl.optimization.enable = mkDefault true;
    })

    # Performance profile-based optimizations
    (mkIf (cfg.autoOptimize && (cfg.profile or performanceProfile) == "high-performance") {
      # High-performance optimizations
      powerManagement.cpuFreqGovernor = "performance";
      
      # Kernel optimizations for performance
      boot.kernel.sysctl = {
        "kernel.sched_migration_cost_ns" = 5000000;
        "kernel.sched_autogroup_enabled" = 0;
        "net.core.busy_poll" = 50;
        "net.core.busy_read" = 50;
      };

      # High-performance I/O settings
      boot.kernelParams = [
        "mitigations=off"  # Disable CPU vulnerability mitigations for max performance
        "preempt=none"     # Disable preemption for better throughput
      ];
    })

    (mkIf (cfg.autoOptimize && (cfg.profile or performanceProfile) == "resource-constrained") {
      # Resource-constrained optimizations
      powerManagement.cpuFreqGovernor = "powersave";
      
      # Conservative kernel settings
      boot.kernel.sysctl = {
        "vm.laptop_mode" = 5;
        "kernel.timer_migration" = 1;
      };

      # Disable resource-intensive features
      services.xserver.desktopManager.gnome.enable = mkForce false;
      services.printing.enable = mkDefault false;
      hardware.bluetooth.enable = mkDefault false;
    })

    # Hardware-specific packages
    {
      environment.systemPackages = with pkgs; [
        # Hardware detection tools
        lshw
        pciutils
        usbutils
        dmidecode
        
        # CPU-specific tools
        (mkIf (hardwareProfile.cpu.vendor == "intel") intel-gpu-tools)
        (mkIf (hardwareProfile.cpu.vendor == "amd") radeontop)
        
        # Storage tools
        (mkIf hardwareProfile.storage.hasNVMe nvme-cli)
        smartmontools
        hdparm
        
        # Performance monitoring
        htop
        iotop
        powertop
        
        # Hardware testing
        memtest86plus
        stress-ng
      ];
    }
  ]);
}