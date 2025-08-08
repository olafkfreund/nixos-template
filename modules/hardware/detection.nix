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
        lib.hasInfix "QEMU" ((builtins.readFile "/sys/class/dmi/id/product_name") or "");
      hasVMwareeDmi = builtins.pathExists "/sys/class/dmi/id/sys_vendor" &&
        lib.hasInfix "VMware" ((builtins.readFile "/sys/class/dmi/id/sys_vendor") or "");
      hasVirtualBoxDmi = builtins.pathExists "/sys/class/dmi/id/product_name" &&
        lib.hasInfix "VirtualBox" ((builtins.readFile "/sys/class/dmi/id/product_name") or "");
      hasHyperVDmi = builtins.pathExists "/sys/class/dmi/id/sys_vendor" &&
        lib.hasInfix "Microsoft Corporation" ((builtins.readFile "/sys/class/dmi/id/sys_vendor") or "");
      hasWSLInterop = builtins.pathExists "/proc/sys/fs/binfmt_misc/WSLInterop";
      hasDockerEnv = builtins.pathExists "/.dockerenv";
      hasContainerEnv = builtins.getEnv "container" != "";
    in
    {
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
      cpuinfo =
        if builtins.pathExists "/proc/cpuinfo"
        then builtins.readFile "/proc/cpuinfo"
        else "";

      # CPU vendor detection
      isIntel = lib.hasInfix "GenuineIntel" cpuinfo;
      isAMD = lib.hasInfix "AuthenticAMD" cpuinfo;
      isARM = lib.hasInfix "ARM" cpuinfo || pkgs.stdenv.hostPlatform.isAarch64;

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
        in
        builtins.length processorLines;

      # CPU model detection
      modelName =
        let
          modelLines = builtins.filter (line: lib.hasPrefix "model name" line)
            (lib.splitString "\n" cpuinfo);
          firstModelLine = if modelLines != [ ] then builtins.head modelLines else "";
          modelMatch = builtins.match "model name[[:space:]]*:[[:space:]]*(.*)" firstModelLine;
        in
        if modelMatch != null then builtins.head modelMatch else "Unknown CPU";
    in
    {
      vendor =
        if isIntel then "intel"
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
      meminfo =
        if builtins.pathExists "/proc/meminfo"
        then builtins.readFile "/proc/meminfo"
        else "";

      # Extract total memory in KB
      totalMemMatch = builtins.match ".*MemTotal:[[:space:]]*([0-9]+) kB.*" meminfo;
      totalMemKB =
        if totalMemMatch != null
        then lib.strings.toInt (builtins.head totalMemMatch)
        else 0;

      # Convert to GB and classify
      totalMemGB = totalMemKB / 1024 / 1024;

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
      # Detect if we're on SSD or HDD
      hasNVMe = builtins.pathExists "/sys/block" &&
        builtins.any (dev: lib.hasPrefix "nvme" dev)
          (builtins.attrNames ((builtins.readDir "/sys/block") or { }));

      hasSSD = builtins.pathExists "/sys/block" &&
        builtins.any
          (dev:
            let rotationalFile = "/sys/block/${dev}/queue/rotational";
            in builtins.pathExists rotationalFile &&
              builtins.readFile rotationalFile == "0\n"
          )
          (builtins.attrNames ((builtins.readDir "/sys/block") or { }));
    in
    {
      hasNVMe = hasNVMe;
      hasSSD = hasSSD || hasNVMe; # NVMe is always SSD
      primaryType =
        if hasNVMe then "nvme"
        else if hasSSD then "ssd"
        else "hdd";
    };

  detectGPU =
    let
      # Check for GPU vendors
      hasNvidiaDevice = builtins.pathExists "/proc/driver/nvidia";
      hasAMDDevice = builtins.pathExists "/sys/class/drm" &&
        builtins.any (dev: lib.hasInfix "amd" dev)
          (builtins.attrNames ((builtins.readDir "/sys/class/drm") or { }));
      hasIntelDevice = builtins.pathExists "/sys/class/drm" &&
        builtins.any (dev: lib.hasInfix "intel" dev)
          (builtins.attrNames ((builtins.readDir "/sys/class/drm") or { }));
    in
    {
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
      # VM guest optimizations
      services.qemuGuest.enable = mkDefault true;
      services.spice-vdagentd.enable = mkDefault true;

      # VM-specific kernel modules
      boot.kernelModules = [
        "virtio_net"
        "virtio_pci"
        "virtio_mmio"
        "virtio_blk"
        "virtio_scsi"
        "virtio_console"
      ];

      # Disable unnecessary services in VMs
      services.smartd.enable = false;
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
        memtest86plus
        stress-ng
      ];
    }
  ]);
}
