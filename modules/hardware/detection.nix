# Advanced Hardware Detection and Optimization
# Automatically detects hardware characteristics and applies appropriate optimizations

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.hardware.detection;

  # Safe file reading function with fallback
  safeReadFile = path: fallback:
    if builtins.pathExists path
    then (builtins.readFile path) or fallback
    else fallback;

  # Hardware detection functions with robust fallbacks
  detectVirtualization =
    let
      # Check for common virtualization indicators with safe fallbacks
      productName = safeReadFile "/sys/class/dmi/id/product_name" "";
      sysVendor = safeReadFile "/sys/class/dmi/id/sys_vendor" "";

      hasQemuDmi = lib.hasInfix "QEMU" productName;
      hasVMwareeDmi = lib.hasInfix "VMware" sysVendor || lib.hasInfix "VMware" productName;
      hasVirtualBoxDmi = lib.hasInfix "VirtualBox" productName;
      hasHyperVDmi = lib.hasInfix "Microsoft Corporation" sysVendor ||
        lib.hasInfix "Hyper-V" productName;
      hasWSLInterop = builtins.pathExists "/proc/sys/fs/binfmt_misc/WSLInterop" ||
        builtins.pathExists "/run/WSL";
      hasDockerEnv = builtins.pathExists "/.dockerenv";
      hasContainerEnv = builtins.getEnv "container" != "";

      # Additional detection methods
      hasSystemdContainer = builtins.getEnv "SYSTEMD_VIRTUALIZATION" != "";
      hasVirtWhat = builtins.pathExists "/proc/xen" ||
        lib.hasInfix "paravirt" (safeReadFile "/proc/cpuinfo" "");
    in
    {
      isVirtualMachine = hasQemuDmi || hasVMwareeDmi || hasVirtualBoxDmi || hasHyperVDmi;
      isWSL = hasWSLInterop;
      isContainer = hasDockerEnv || hasContainerEnv || hasSystemdContainer;
      virtualization =
        if hasQemuDmi then "qemu"
        else if hasVMwareeDmi then "vmware"
        else if hasVirtualBoxDmi then "virtualbox"
        else if hasHyperVDmi then "hyperv"
        else if hasWSLInterop then "wsl"
        else if hasContainerEnv || hasSystemdContainer then "container"
        else if hasVirtWhat then "virtualized" # Generic virtualization detected
        else "bare-metal";
    };

  detectCPU =
    let
      cpuinfo = safeReadFile "/proc/cpuinfo" "";

      # Fallback CPU detection using Nix platform information
      platformVendor =
        if pkgs.stdenv.hostPlatform.isx86_64 || pkgs.stdenv.hostPlatform.isx86_32
        then "x86"
        else if pkgs.stdenv.hostPlatform.isAarch64
        then "arm"
        else if pkgs.stdenv.hostPlatform.isRiscV64
        then "riscv"
        else "unknown";

      # CPU vendor detection with fallbacks
      isIntel = lib.hasInfix "GenuineIntel" cpuinfo || lib.hasInfix "Intel" cpuinfo;
      isAMD = lib.hasInfix "AuthenticAMD" cpuinfo || lib.hasInfix "AMD" cpuinfo;
      isARM = lib.hasInfix "ARM" cpuinfo || pkgs.stdenv.hostPlatform.isAarch64;

      # CPU features detection with safe parsing
      flags = lib.concatStringsSep " "
        (lib.filter (line: lib.hasPrefix "flags" line || lib.hasPrefix "Features" line)
          (lib.splitString "\n" cpuinfo));

      hasAVX = lib.hasInfix " avx " flags || lib.hasInfix " avx\t" flags;
      hasAVX2 = lib.hasInfix " avx2 " flags || lib.hasInfix " avx2\t" flags;
      hasAVX512 = lib.hasInfix "avx512" flags;
      hasSSE4 = lib.hasInfix "sse4" flags;
      hasAES = lib.hasInfix " aes " flags || lib.hasInfix " aes\t" flags;

      # Core count detection with multiple methods
      coreCount =
        let
          # Method 1: Count processor entries in /proc/cpuinfo
          processorLines = builtins.filter (line: lib.hasPrefix "processor" line)
            (lib.splitString "\n" cpuinfo);
          procCount = builtins.length processorLines;

          # Method 2: Try nproc via /proc/sys/kernel/nproc
          nprocValue =
            let nprocContent = safeReadFile "/sys/devices/system/cpu/online" "";
            in if nprocContent != ""
            then # Parse range like "0-3" or "0-7"
              let
                cleanContent = lib.strings.trim nprocContent;
                parts = lib.splitString "-" cleanContent;
              in
              if builtins.length parts == 2
              then (lib.strings.toInt (builtins.elemAt parts 1)) + 1
              else 1
            else 0;

          # Method 3: Fallback based on platform
          platformDefault =
            if pkgs.stdenv.hostPlatform.isx86_64 then 4
            else if pkgs.stdenv.hostPlatform.isAarch64 then 4
            else 2;
        in
        if procCount > 0 then procCount
        else if nprocValue > 0 then nprocValue
        else platformDefault;

      # CPU model detection with improved parsing
      modelName =
        let
          modelLines = builtins.filter (line: lib.hasPrefix "model name" line)
            (lib.splitString "\n" cpuinfo);
          firstModelLine = if modelLines != [ ] then builtins.head modelLines else "";
          modelMatch = builtins.match "model name[[:space:]]*:[[:space:]]*(.*)" firstModelLine;

          # Fallback for ARM
          armModelLines = builtins.filter (line: lib.hasPrefix "Processor" line)
            (lib.splitString "\n" cpuinfo);
          armModelLine = if armModelLines != [ ] then builtins.head armModelLines else "";
          armModelMatch = builtins.match "Processor[[:space:]]*:[[:space:]]*(.*)" armModelLine;
        in
        if modelMatch != null then lib.strings.trim (builtins.head modelMatch)
        else if armModelMatch != null then lib.strings.trim (builtins.head armModelMatch)
        else "${platformVendor} CPU";
    in
    {
      vendor =
        if isIntel then "intel"
        else if isAMD then "amd"
        else if isARM then "arm"
        else platformVendor;
      cores = coreCount;
      model = modelName;
      features = {
        inherit hasAVX hasAVX2 hasAVX512 hasSSE4 hasAES;
      };
      # Additional metadata for debugging
      detection = {
        cpuinfoAvailable = cpuinfo != "";
        detectionMethod =
          if cpuinfo != "" then "procfs"
          else "platform-fallback";
      };
    };

  detectMemory =
    let
      meminfo = safeReadFile "/proc/meminfo" "";

      # Extract total memory in KB with robust parsing
      totalMemMatch = builtins.match ".*MemTotal:[[:space:]]*([0-9]+) kB.*" meminfo;
      totalMemKB =
        if totalMemMatch != null
        then
          let
            memStr = builtins.head totalMemMatch;
            # Safe integer conversion
            memInt = builtins.fromJSON memStr;
          in
          memInt
        else
        # Fallback estimation based on common system configurations
          let
            # Try alternative detection methods
            sysMemInfo = safeReadFile "/sys/devices/system/memory/auto_online_blocks" "";
          in
          if pkgs.stdenv.hostPlatform.isx86_64 then 8388608  # 8GB default for x64
          else if pkgs.stdenv.hostPlatform.isAarch64 then 4194304  # 4GB default for ARM64
          else 2097152; # 2GB minimal default

      # Convert to GB with safer arithmetic
      totalMemGB =
        if totalMemKB > 0
        then totalMemKB / 1024 / 1024
        else 8; # 8GB reasonable default for modern systems

      memoryClass =
        if totalMemGB >= 32 then "high"
        else if totalMemGB >= 8 then "medium"
        else if totalMemGB >= 4 then "low"
        else "minimal";
    in
    {
      totalGB = totalMemGB;
      class = memoryClass;
    };

  detectStorage =
    let
      # Safe directory reading with fallbacks
      blockDevs =
        if builtins.pathExists "/sys/block"
        then (builtins.readDir "/sys/block") or { }
        else { };

      devNames = builtins.attrNames blockDevs;

      # Detect NVMe with multiple methods
      hasNVMe =
        builtins.any (dev: lib.hasPrefix "nvme" dev) devNames ||
        builtins.pathExists "/dev/nvme0n1" ||
        builtins.pathExists "/sys/class/nvme";

      # Detect SSD with robust checking
      hasSSD = hasNVMe || # NVMe is always SSD
        builtins.any
          (dev:
            let
              rotationalFile = "/sys/block/${dev}/queue/rotational";
              rotationalContent = safeReadFile rotationalFile "1";
            in
            (lib.hasPrefix "sd" dev || lib.hasPrefix "vd" dev) &&
              (rotationalContent == "0\n" || rotationalContent == "0")
          )
          devNames;

      # Additional storage type detection
      hasVirtIO = builtins.any (dev: lib.hasPrefix "vd" dev) devNames;
      hasMMC = builtins.any (dev: lib.hasPrefix "mmcblk" dev) devNames;
    in
    {
      inherit hasNVMe hasSSD hasVirtIO hasMMC;
      primaryType =
        if hasNVMe then "nvme"
        else if hasSSD then "ssd"
        else if hasVirtIO then "virtio" # Virtual storage
        else if hasMMC then "mmc" # eMMC/SD storage
        else "hdd";
      # Detection metadata
      detection = {
        devicesFound = devNames;
        sysBlockAvailable = blockDevs != { };
      };
    };

  detectGPU =
    let
      # Check for GPU vendors with multiple detection methods
      hasNvidiaDevice =
        builtins.pathExists "/proc/driver/nvidia" ||
        builtins.pathExists "/dev/nvidia0" ||
        builtins.pathExists "/sys/module/nvidia";

      drmDevs =
        if builtins.pathExists "/sys/class/drm"
        then (builtins.readDir "/sys/class/drm") or { }
        else { };

      drmDevNames = builtins.attrNames drmDevs;

      hasAMDDevice =
        builtins.any (dev: lib.hasInfix "amd" dev || lib.hasInfix "radeon" dev) drmDevNames ||
        builtins.pathExists "/sys/module/amdgpu" ||
        builtins.pathExists "/sys/module/radeon";

      hasIntelDevice =
        builtins.any (dev: lib.hasInfix "intel" dev || lib.hasInfix "i915" dev) drmDevNames ||
        builtins.pathExists "/sys/module/i915" ||
        builtins.pathExists "/sys/module/xe"; # Intel Xe graphics

      # Additional GPU detection
      hasVirtIOGPU =
        builtins.any (dev: lib.hasInfix "virtio" dev) drmDevNames ||
        builtins.pathExists "/sys/module/virtio_gpu";

      hasNouveau = builtins.pathExists "/sys/module/nouveau";
    in
    {
      hasNvidia = hasNvidiaDevice;
      hasAMD = hasAMDDevice;
      hasIntel = hasIntelDevice;
      hasVirtIO = hasVirtIOGPU;
      hasNouveau = hasNouveau;
      hasDiscrete = hasNvidiaDevice || hasAMDDevice;
      # Detection metadata
      detection = {
        drmDevices = drmDevNames;
        drmAvailable = drmDevs != { };
      };
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
    enable = mkEnableOption "automatic hardware detection and optimization" // {
      description = ''
        Enable comprehensive hardware detection and automatic optimization.
        This module analyzes system hardware characteristics and applies
        appropriate optimizations for CPU, memory, storage, and GPU.

        Detection includes:
        - CPU vendor, cores, features (AVX, AES, etc.)
        - Memory size and classification (minimal/low/medium/high)
        - Storage type detection (NVMe, SSD, HDD, VirtIO)
        - GPU vendor detection (Intel, AMD, NVIDIA)
        - Virtualization environment detection (QEMU, VMware, WSL, etc.)

        Results are made available to other modules for optimization decisions.
      '';
    };

    autoOptimize = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically apply hardware-specific optimizations based on detection results.

        When enabled, applies:
        - CPU vendor-specific optimizations (microcode, power states)
        - Memory-based kernel parameter tuning
        - Storage I/O scheduler optimization
        - GPU driver configuration
        - Virtualization environment adaptations

        Disable if you prefer manual hardware configuration or experience
        compatibility issues with automatic optimizations.
      '';
    };

    profile = mkOption {
      type = types.nullOr (types.enum [ "minimal" "resource-constrained" "balanced" "high-performance" ]);
      default = null;
      description = ''
        Override automatic performance profile detection with manual classification.

        Automatic detection determines profile based on:
        - `high-performance`: ≥32GB RAM, ≥8 cores, NVMe storage
        - `balanced`: ≥8GB RAM, ≥4 cores, SSD storage
        - `resource-constrained`: <8GB RAM
        - `minimal`: Fallback for limited hardware

        Manual override useful for specialized workloads or testing different
        optimization levels on the same hardware.
      '';
      example = "high-performance";
    };

    reporting = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable hardware detection reporting and logging.

          When enabled, creates a systemd service that logs detected hardware
          characteristics at boot time. Useful for troubleshooting hardware
          detection issues and verifying optimization decisions.

          Reports include CPU, memory, storage, GPU, and virtualization details.
        '';
      };

      logLevel = mkOption {
        type = types.enum [ "info" "debug" ];
        default = "info";
        description = ''
          Hardware detection logging verbosity level:

          - `info`: Basic hardware summary (CPU, memory, storage type, performance profile)
          - `debug`: Detailed hardware information including CPU features, GPU devices,
            storage devices, and detection methodology used for each component

          Debug level useful for troubleshooting detection issues or optimization problems.
        '';
      };
    };

    overrides = {
      cpu = {
        vendor = mkOption {
          type = types.nullOr (types.enum [ "intel" "amd" "arm" ]);
          default = null;
          description = ''
            Override automatic CPU vendor detection.

            Useful when running in virtualized environments where CPU vendor
            detection may be unreliable, or when testing vendor-specific
            optimizations on different hardware.

            When set, applies vendor-specific optimizations regardless of
            actual hardware detected.
          '';
          example = "intel";
        };

        cores = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = ''
            Override automatic CPU core count detection.

            Useful when automatic detection fails (e.g., in some virtualized
            environments) or when you want to limit the number of cores used
            for performance optimization calculations.

            Affects build parallelism, memory tuning, and CPU governor selection.
          '';
          example = 8;
        };
      };

      virtualization = {
        type = mkOption {
          type = types.nullOr (types.enum [ "bare-metal" "qemu" "vmware" "virtualbox" "hyperv" "wsl" "container" ]);
          default = null;
          description = ''
            Override automatic virtualization environment detection.

            Detection may fail in some environments or you may want to force
            specific virtualization optimizations. Affects:
            - Guest tools and drivers installation
            - Power management settings
            - I/O scheduler selection
            - Service configuration (e.g., disable hardware monitoring in VMs)

            Use "bare-metal" to disable all virtualization optimizations.
          '';
          example = "qemu";
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
        description = "Hardware Detection and Reporting Service";
        wantedBy = [ "multi-user.target" ];
        after = [ "basic.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart =
            let
              # Build safe hardware detection script
              detectionScript = pkgs.writeShellScript "hardware-detection" ''
                set -euo pipefail

                # Safe logging function
                log_info() {
                  echo "$1" | ${pkgs.systemd}/bin/systemd-cat -t hardware-detection -p info
                }

                log_debug() {
                  echo "$1" | ${pkgs.systemd}/bin/systemd-cat -t hardware-detection -p debug
                }

                # Header
                log_info "=== NixOS Hardware Detection Report ==="

                # CPU Information
                if [[ -r /proc/cpuinfo ]]; then
                  CPU_VENDOR=$(grep -m1 "vendor_id" /proc/cpuinfo | cut -d: -f2 | xargs || echo "unknown")
                  CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs || echo "Unknown CPU")
                  CPU_CORES=$(nproc || echo "1")
                  log_info "CPU: $CPU_VENDOR $CPU_MODEL ($CPU_CORES cores)"
                else
                  log_info "CPU: Information unavailable"
                fi

                # Memory Information
                if [[ -r /proc/meminfo ]]; then
                  MEMORY_KB=$(grep "MemTotal" /proc/meminfo | awk '{print $2}' || echo "0")
                  MEMORY_GB=$(( MEMORY_KB / 1024 / 1024 ))
                  if (( MEMORY_GB >= 32 )); then
                    MEMORY_CLASS="high"
                  elif (( MEMORY_GB >= 8 )); then
                    MEMORY_CLASS="medium"
                  elif (( MEMORY_GB >= 4 )); then
                    MEMORY_CLASS="low"
                  else
                    MEMORY_CLASS="minimal"
                  fi
                  log_info "Memory: ''${MEMORY_GB}GB ($MEMORY_CLASS)"
                else
                  log_info "Memory: Information unavailable"
                fi

                # Storage Information
                if [[ -d /sys/block ]]; then
                  if ls /sys/block/nvme* >/dev/null 2>&1; then
                    STORAGE_TYPE="nvme"
                  elif ls /sys/block/sd* >/dev/null 2>&1; then
                    # Check if any SSD
                    STORAGE_TYPE="hdd"
                    for dev in /sys/block/sd*; do
                      if [[ -r "$dev/queue/rotational" ]] && [[ $(cat "$dev/queue/rotational" 2>/dev/null) == "0" ]]; then
                        STORAGE_TYPE="ssd"
                        break
                      fi
                    done
                  else
                    STORAGE_TYPE="unknown"
                  fi
                  log_info "Storage: $STORAGE_TYPE"
                else
                  log_info "Storage: Information unavailable"
                fi

                # Virtualization Detection
                VIRT_TYPE="bare-metal"
                if [[ -r /sys/class/dmi/id/product_name ]]; then
                  PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
                  case "$PRODUCT_NAME" in
                    *QEMU*) VIRT_TYPE="qemu" ;;
                    *VirtualBox*) VIRT_TYPE="virtualbox" ;;
                    *VMware*) VIRT_TYPE="vmware" ;;
                  esac
                fi

                if [[ -r /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
                  VIRT_TYPE="wsl"
                elif [[ -f /.dockerenv ]] || [[ -n "''${container:-}" ]]; then
                  VIRT_TYPE="container"
                fi

                log_info "Virtualization: $VIRT_TYPE"

                # Performance Profile (determined by script)
                if [[ "$MEMORY_CLASS" == "high" && "$CPU_CORES" -ge 8 && "$STORAGE_TYPE" == "nvme" ]]; then
                  PROFILE="high-performance"
                elif [[ "$MEMORY_CLASS" == "medium" && "$CPU_CORES" -ge 4 && ("$STORAGE_TYPE" == "ssd" || "$STORAGE_TYPE" == "nvme") ]]; then
                  PROFILE="balanced"
                elif [[ "$MEMORY_CLASS" == "low" ]]; then
                  PROFILE="resource-constrained"
                else
                  PROFILE="minimal"
                fi

                log_info "Performance Profile: $PROFILE"

                ${optionalString (cfg.reporting.logLevel == "debug") ''
                # Debug Information
                log_debug "=== Debug Information ==="

                # CPU Features
                if [[ -r /proc/cpuinfo ]]; then
                  CPU_FLAGS=$(grep -m1 "^flags" /proc/cpuinfo | cut -d: -f2 || echo "")
                  AVX=$(echo "$CPU_FLAGS" | grep -o "avx" | head -1 || echo "false")
                  AVX2=$(echo "$CPU_FLAGS" | grep -o "avx2" | head -1 || echo "false")
                  AES=$(echo "$CPU_FLAGS" | grep -o "aes" | head -1 || echo "false")
                  log_debug "CPU Features: AVX=$([[ -n $AVX ]] && echo true || echo false) AVX2=$([[ -n $AVX2 ]] && echo true || echo false) AES=$([[ -n $AES ]] && echo true || echo false)"
                fi

                # GPU Detection
                GPU_NVIDIA="false"
                GPU_AMD="false"
                GPU_INTEL="false"

                if [[ -d /proc/driver/nvidia ]]; then
                  GPU_NVIDIA="true"
                fi

                if [[ -d /sys/class/drm ]]; then
                  if ls /sys/class/drm/*amd* >/dev/null 2>&1; then
                    GPU_AMD="true"
                  fi
                  if ls /sys/class/drm/*intel* >/dev/null 2>&1; then
                    GPU_INTEL="true"
                  fi
                fi

                log_debug "GPU: NVIDIA=$GPU_NVIDIA AMD=$GPU_AMD Intel=$GPU_INTEL"

                # Storage Details
                if [[ -d /sys/block ]]; then
                  HAS_NVME="false"
                  HAS_SSD="false"

                  if ls /sys/block/nvme* >/dev/null 2>&1; then
                    HAS_NVME="true"
                    HAS_SSD="true"
                  elif ls /sys/block/sd* >/dev/null 2>&1; then
                    for dev in /sys/block/sd*; do
                      if [[ -r "$dev/queue/rotational" ]] && [[ $(cat "$dev/queue/rotational" 2>/dev/null) == "0" ]]; then
                        HAS_SSD="true"
                        break
                      fi
                    done
                  fi

                  log_debug "Storage: NVMe=$HAS_NVME SSD=$HAS_SSD"
                fi
                ''}

                log_info "=== Hardware Detection Complete ==="
              '';
            in
            toString detectionScript;
        };
      };

      # Environment variables for other services
      environment.variables = {
        NIXOS_HARDWARE_PROFILE = toString (cfg.profile or performanceProfile);
        NIXOS_CPU_VENDOR = toString hardwareProfile.cpu.vendor;
        NIXOS_VIRTUALIZATION = toString hardwareProfile.virtualization.virtualization;
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
        "vm.swappiness" = mkDefault 10;
        "vm.vfs_cache_pressure" = mkDefault 50;
        "vm.dirty_background_ratio" = mkDefault 5;
        "vm.dirty_ratio" = mkDefault 10;
      };

      # Disable memory-intensive features
      services.gnome.tinysparql.enable = false; # Renamed from tracker
      services.gnome.localsearch.enable = false; # Renamed from tracker-miners
    })

    (mkIf (cfg.autoOptimize && hardwareProfile.memory.class == "high") {
      # High-memory optimizations
      boot.kernel.sysctl = {
        "vm.swappiness" = mkDefault 1;
        "vm.vfs_cache_pressure" = mkDefault 200;
        "vm.dirty_background_ratio" = mkDefault 10;
        "vm.dirty_ratio" = mkDefault 20;
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
      # VM services optimization
      services = {
        # VM guest optimizations
        qemuGuest.enable = mkDefault true;
        spice-vdagentd.enable = mkDefault true;

        # Disable unnecessary services in VMs
        smartd.enable = false;
      };

      # VM-specific kernel modules
      boot.kernelModules = [
        "virtio_net"
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        "virtio_scsi"
        "virtio_console"
      ];
      powerManagement.enable = false;

      # VM-optimized scheduler
      boot.kernelParams = [ "elevator=noop" ];
    })

    (mkIf (cfg.autoOptimize && hardwareProfile.virtualization.isWSL) {
      # WSL-specific optimizations
      # Note: Enable WSL-specific optimizations if WSL module is available
      # modules.wsl.optimization.enable = mkDefault true;

      # Basic WSL optimizations
      boot.kernelParams = [ "systemd.unified_cgroup_hierarchy=0" ];
      powerManagement.enable = false;
      services.resolved.enable = false; # WSL handles DNS
    })

    # Performance profile-based optimizations
    (mkIf (cfg.autoOptimize && (cfg.profile or performanceProfile) == "high-performance") {
      # High-performance optimizations
      powerManagement.cpuFreqGovernor = "performance";

      # Kernel optimizations for performance
      boot.kernel.sysctl = {
        "kernel.sched_migration_cost_ns" = mkDefault 5000000;
        "kernel.sched_autogroup_enabled" = mkDefault 0;
        "net.core.busy_poll" = mkDefault 50;
        "net.core.busy_read" = mkDefault 50;
      };

      # High-performance I/O settings
      boot.kernelParams = [
        "mitigations=off" # Disable CPU vulnerability mitigations for max performance
        "preempt=none" # Disable preemption for better throughput
      ];
    })

    (mkIf (cfg.autoOptimize && (cfg.profile or performanceProfile) == "resource-constrained") {
      # Resource-constrained optimizations
      powerManagement.cpuFreqGovernor = "powersave";

      # Conservative kernel settings
      boot.kernel.sysctl = {
        "vm.laptop_mode" = mkDefault 5;
        "kernel.timer_migration" = mkDefault 1;
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
        stress-ng
      ] ++ lib.optionals pkgs.stdenv.hostPlatform.isx86 [
        # x86-only hardware testing tools
        memtest86plus
      ];
    }
  ]);
}
