# WSL2 Performance Optimizations
# System optimizations specific to WSL2 environment

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.wsl.optimization;
in

{
  options.modules.wsl.optimization = {
    enable = mkEnableOption "WSL2 performance optimizations";

    memory = mkOption {
      type = types.submodule {
        options = {
          swappiness = mkOption {
            type = types.int;
            default = 10;
            description = "VM swappiness value (0-100, lower = less swap usage)";
          };

          cacheOptimization = mkOption {
            type = types.bool;
            default = true;
            description = "Enable file system cache optimizations";
          };

          hugepages = mkOption {
            type = types.bool;
            default = false;
            description = "Enable transparent hugepages (can improve performance for some workloads)";
          };
        };
      };
      default = { };
      description = "Memory management optimizations";
    };

    filesystem = mkOption {
      type = types.submodule {
        options = {
          mountOptimizations = mkOption {
            type = types.bool;
            default = true;
            description = "Enable filesystem mount optimizations for WSL2";
          };

          tmpfsSize = mkOption {
            type = types.str;
            default = "2G";
            description = "Size limit for /tmp tmpfs";
          };

          noCOW = mkOption {
            type = types.bool;
            default = true;
            description = "Disable copy-on-write for better performance with large files";
          };
        };
      };
      default = { };
      description = "Filesystem optimizations";
    };

    services = mkOption {
      type = types.submodule {
        options = {
          disableUnneeded = mkOption {
            type = types.bool;
            default = true;
            description = "Disable services not needed in WSL2";
          };

          optimizeSystemd = mkOption {
            type = types.bool;
            default = true;
            description = "Optimize systemd for WSL2 environment";
          };
        };
      };
      default = { };
      description = "Service optimizations";
    };

    development = mkOption {
      type = types.submodule {
        options = {
          fastBuild = mkOption {
            type = types.bool;
            default = true;
            description = "Enable fast build optimizations for development";
          };

          cacheNix = mkOption {
            type = types.bool;
            default = true;
            description = "Enable Nix store optimizations";
          };
        };
      };
      default = { };
      description = "Development-focused optimizations";
    };
  };

  config = mkIf cfg.enable {
    # Memory optimizations
    boot.kernel.sysctl = mkMerge [
      # Basic memory management
      {
        "vm.swappiness" = cfg.memory.swappiness;
        "vm.dirty_ratio" = 15;
        "vm.dirty_background_ratio" = 5;
        "vm.vfs_cache_pressure" = 50;
      }

      # Cache optimizations
      (mkIf cfg.memory.cacheOptimization {
        "vm.dirty_expire_centisecs" = 3000;
        "vm.dirty_writeback_centisecs" = 500;
        "vm.min_free_kbytes" = 65536;
      })

      # Hugepages configuration
      (mkIf cfg.memory.hugepages {
        "vm.nr_hugepages" = 0; # Let system decide
        "kernel.shmmax" = 68719476736; # 64GB
      })

      # WSL2-specific kernel optimizations (additional)
      {
        # Scheduler optimizations for WSL2
        "kernel.sched_migration_cost_ns" = 5000000;
        "kernel.sched_autogroup_enabled" = 1;

        # I/O scheduler optimizations
        "vm.page-cluster" = 0; # Disable page clustering for better latency

        # Network optimizations (already covered in networking.nix, but ensuring key ones)
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      }
    ];

    # Filesystem optimizations
    fileSystems = mkMerge [
      # Optimize /tmp with tmpfs
      {
        "/tmp" = {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [
            "rw"
            "nosuid"
            "nodev"
            "size=${cfg.filesystem.tmpfsSize}"
            "mode=1777"
          ];
        };
      }

      # WSL2 mount optimizations
      (mkIf cfg.filesystem.mountOptimizations {
        "/mnt/c" = {
          options = [
            "metadata"
            "uid=1000"
            "gid=1000"
            "umask=022"
            "fmask=011"
            "case=off"
          ];
        };
      })
    ];

    # Service optimizations
    systemd = mkMerge [
      # Optimize systemd for WSL2
      (mkIf cfg.services.optimizeSystemd {
        # Faster boot times
        services = {
          systemd-resolved.enable = false;
          systemd-networkd.enable = false;
          systemd-timesyncd.enable = true;
        };

        # Optimize service timeouts
        extraConfig = ''
          DefaultTimeoutStopSec=10s
          DefaultTimeoutStartSec=30s
          DefaultDeviceTimeoutSec=10s
        '';

        # User service optimizations
        user.extraConfig = ''
          DefaultTimeoutStopSec=10s
          DefaultTimeoutStartSec=10s
        '';
      })

      # Disable unneeded services
      (mkIf cfg.services.disableUnneeded {
        services = {
          # Power management not needed in WSL
          upower.enable = false;
          thermald.enable = false;

          # Hardware services not applicable
          fwupd.enable = false;

          # Desktop services not needed for headless
          accounts-daemon.enable = mkDefault false;

          # Bluetooth not available
          bluetooth.enable = false;
        };

        # Mask services that can't be properly disabled
        systemMasks = [
          "systemd-backlight@.service"
          "systemd-rfkill.service"
          "systemd-rfkill.socket"
        ];
      })
    ];

    # Development optimizations
    nix = mkIf cfg.development.cacheNix {
      settings = {
        # Build optimizations
        max-jobs = "auto";
        cores = 0; # Use all available cores

        # Storage optimizations
        auto-optimise-store = true;

        # Cache optimizations
        keep-outputs = true;
        keep-derivations = true;

        # Faster downloads
        http-connections = 25;

        # WSL2-specific optimizations
        sandbox = false; # Sandbox can be problematic in WSL2
      };

      # Garbage collection optimization
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    # Build environment optimizations
    environment = mkIf cfg.development.fastBuild {
      variables = {
        # Compiler optimizations
        MAKEFLAGS = "-j$(nproc)";

        # Rust optimizations
        CARGO_BUILD_JOBS = "$(nproc)";

        # Node.js optimizations
        UV_THREADPOOL_SIZE = "$(nproc)";

        # Python optimizations
        PYTHONDONTWRITEBYTECODE = "1";
        PYTHONUNBUFFERED = "1";
      };
    };

    # WSL2-specific kernel modules and parameters
    boot = {
      # Disable modules not needed in WSL2
      blacklistedKernelModules = [
        "pcspkr" # PC speaker
        "snd_pcsp" # PC speaker sound
      ];

    };

    # Performance monitoring tools
    environment.systemPackages = with pkgs; [
      # System monitoring
      htop
      iotop
      iftop

      # Performance analysis
      sysstat # iostat, vmstat, etc.
      perf-tools

      # WSL2-specific utilities
      pciutils # lspci
      usbutils # lsusb

      # Development performance tools
      time
      hyperfine # Benchmarking tool
    ];

    # WSL2 performance tuning script
    environment.etc."wsl-scripts/performance-tune.sh" = {
      text = ''
        #!/bin/bash
        # WSL2 Performance Tuning Script
        
        echo "=== WSL2 Performance Tuning ==="
        
        # Check current swappiness
        echo "Current swappiness: $(cat /proc/sys/vm/swappiness)"
        
        # Check memory usage
        echo "Memory usage:"
        free -h
        
        # Check I/O scheduler
        echo "I/O schedulers:"
        find /sys/block -name scheduler -exec sh -c 'echo -n "$1: "; cat "$1"' _ {} \;
        
        # Check CPU frequency scaling
        if [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
          echo "CPU frequency scaling governor:"
          cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u
        else
          echo "CPU frequency scaling not available (normal for WSL2)"
        fi
        
        # Check mount options
        echo "Important mount points:"
        mount | grep -E "(tmpfs|ext4|ntfs)" | grep -E "(/tmp|/mnt|/)"
        
        # Performance recommendations
        echo ""
        echo "=== Performance Tips ==="
        echo "1. Use 'just clean' regularly to free up space"
        echo "2. Keep Windows drive (C:) files on Windows filesystem for best performance"
        echo "3. Use WSL2 filesystem (/home) for development files"
        echo "4. Consider adjusting Windows WSL2 memory settings in .wslconfig"
        echo "5. Use 'wsl --shutdown' periodically to free up memory"
      '';
      mode = "0755";
    };

    # Add performance tuning script to PATH
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "wsl-performance-tune" ''
        exec /etc/wsl-scripts/performance-tune.sh "$@"
      '')
    ];

    # Systemd service for initial performance tuning
    systemd.services.wsl-performance-init = {
      description = "WSL2 Performance Initialization";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Apply WSL2-specific performance optimizations
        echo "Applying WSL2 performance optimizations..."
        
        # Enable BBR congestion control if available
        if [ -w /proc/sys/net/ipv4/tcp_congestion_control ]; then
          echo bbr > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "BBR not available"
        fi
        
        # Optimize I/O scheduler for SSD (WSL2 typically uses SSD on host)
        for dev in /sys/block/*/queue/scheduler; do
          if [ -f "$dev" ]; then
            echo mq-deadline > "$dev" 2>/dev/null || true
          fi
        done
        
        echo "WSL2 performance optimizations applied"
      '';
    };
  };
}
