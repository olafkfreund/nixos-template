# Advanced Nix Store and System State Optimization
# Provides comprehensive system state management and Nix store optimization

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.core.nixOptimization;
in

{
  options.modules.core.nixOptimization = {
    enable = mkEnableOption "advanced Nix and system state optimization";

    tmpfs = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tmpfs for /tmp with automatic cleanup";
      };

      size = mkOption {
        type = types.str;
        default = "50%";
        description = "Size limit for tmpfs /tmp (percentage or absolute)";
      };
    };

    store = {
      autoOptimise = mkOption {
        type = types.bool;
        default = true;
        description = "Automatically optimize Nix store by hardlinking identical files";
      };

      gc = {
        automatic = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic garbage collection";
        };

        dates = mkOption {
          type = types.str;
          default = "weekly";
          description = "When to run garbage collection";
        };

        options = mkOption {
          type = types.str;
          default = "--delete-older-than 14d";
          description = "Options to pass to nix-collect-garbage";
        };

        persistent = mkOption {
          type = types.bool;
          default = true;
          description = "Ensure GC runs even if system was off during scheduled time";
        };
      };
    };

    experimental = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable experimental Nix features";
      };

      features = mkOption {
        type = types.listOf types.str;
        default = [
          "nix-command"
          "flakes"
          "ca-derivations"
          "recursive-nix"
        ];
        description = "List of experimental features to enable";
      };
    };

    performance = {
      maxJobs = mkOption {
        type = types.either types.int (types.enum [ "auto" ]);
        default = "auto";
        description = "Maximum number of parallel build jobs";
      };

      cores = mkOption {
        type = types.int;
        default = 0;
        description = "Number of CPU cores to use (0 = all available)";
      };

      keepOutputs = mkOption {
        type = types.bool;
        default = true;
        description = "Keep build outputs to enable incremental builds";
      };

      keepDerivations = mkOption {
        type = types.bool;
        default = true;
        description = "Keep derivations for debugging and incremental builds";
      };

      useCgroups = mkOption {
        type = types.bool;
        default = true;
        description = "Use cgroups for better build isolation";
      };
    };
  };

  config = mkIf cfg.enable {
    # Advanced tmpfs configuration
    boot.tmp = mkIf cfg.tmpfs.enable {
      cleanOnBoot = true;
      useTmpfs = true;
      tmpfsSize = cfg.tmpfs.size;
    };

    # Comprehensive Nix configuration
    nix = {
      settings = mkMerge [
        # Store optimization
        (mkIf cfg.store.autoOptimise {
          auto-optimise-store = true;
        })

        # Performance settings
        {
          max-jobs = cfg.performance.maxJobs;
          cores = cfg.performance.cores;
          keep-outputs = cfg.performance.keepOutputs;
          keep-derivations = cfg.performance.keepDerivations;
          use-cgroups = cfg.performance.useCgroups;

          # Build isolation and security
          sandbox = true;
          restrict-eval = false;

          # Network optimization
          http-connections = 25;
          download-attempts = 3;

          # Advanced cache settings
          narinfo-cache-negative-ttl = 3600;
          narinfo-cache-positive-ttl = 432000;

          # Build log optimization
          log-lines = 100;
          show-trace = false;

          # Substituter settings
          builders-use-substitutes = true;
          substitute = true;
        }

        # Experimental features
        (mkIf cfg.experimental.enable {
          experimental-features = cfg.experimental.features;
        })
      ];

      # Advanced garbage collection
      gc = mkIf cfg.store.gc.automatic {
        automatic = true;
        dates = cfg.store.gc.dates;
        options = cfg.store.gc.options;
        persistent = cfg.store.gc.persistent;
      };

      # Store optimization service
      optimise = mkIf cfg.store.autoOptimise {
        automatic = true;
        dates = [ "03:45" ]; # Run at 3:45 AM
      };

      # Advanced build settings for different system types
      distributedBuilds = false; # Disable by default, can be overridden
      buildMachines = [ ]; # Empty by default

      # Registry optimization (inputs available through special args)
      # registry = {
      #   nixpkgs.flake = inputs.nixpkgs;
      # };

      # Channel configuration (for compatibility)
      channel.enable = false; # Prefer flakes over channels
    };

    # System state optimization
    systemd = {
      # Optimize systemd services for faster boot
      services = {
        # Enhanced Nix daemon configuration
        nix-daemon = {
          serviceConfig = {
            LimitNOFILE = mkDefault 65536;
            # CPU and memory limits for build isolation
            CPUQuota = mkDefault "95%";
            MemoryHigh = mkDefault "80%";
            MemoryMax = mkDefault "90%";
          };
        };

        # Nix store optimization service
        nix-store-optimize = mkIf cfg.store.autoOptimise {
          description = "Optimize Nix Store";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${config.nix.package}/bin/nix-store --optimise";
            Nice = 19;
            IOSchedulingClass = 3; # Idle
          };
        };
      };

      # Advanced timer for store optimization
      timers = mkIf cfg.store.autoOptimise {
        nix-store-optimize = {
          description = "Optimize Nix Store Timer";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "45min";
          };
        };
      };

      # Temporary file cleanup optimization
      tmpfiles.rules = [
        # Clean up various temporary directories
        "d /tmp 1777 root root 1d"
        "d /var/tmp 1777 root root 7d"
        "d /run/user 0755 root root -"
        
        # Nix-specific cleanup
        "d /nix/var/nix/gcroots/tmp 0755 root root -"
        "d /nix/var/nix/temproots 0755 root root -"
        
        # Clean up old build logs
        "R! /nix/var/log/nix/drvs 30d"
      ];
    };

    # Note: Filesystem optimization should be done in host-specific configurations
    # to avoid circular dependencies. Example for host configuration:
    # fileSystems."/nix".options = [ "noatime" "compress=zstd:1" "space_cache=v2" ];

    # Memory and process optimization
    security.pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "65536";
      }
      {
        domain = "*";
        type = "hard";
        item = "nofile";
        value = "1048576";
      }
    ];

    # Kernel optimization for Nix builds
    boot.kernel.sysctl = {
      # Optimize for build workloads (use lower priority than system defaults)
      "kernel.pid_max" = mkOverride 1500 4194304;
      "vm.max_map_count" = mkOverride 1500 262144;
      
      # Network optimization for downloads
      "net.core.rmem_max" = mkDefault 134217728;
      "net.core.wmem_max" = mkDefault 134217728;
      "net.ipv4.tcp_rmem" = mkDefault "4096 65536 134217728";
      "net.ipv4.tcp_wmem" = mkDefault "4096 65536 134217728";
      
      # Build performance optimization
      "kernel.sched_autogroup_enabled" = mkDefault 0; # Better for build workloads
    };

    # Environment optimization
    environment = {
      # System-wide environment variables for optimization
      variables = {
        # Nix optimization
        NIX_REMOTE = "daemon";
        
        # Compiler optimization
        MAKEFLAGS = "-j${toString config.nix.settings.max-jobs}";
        
        # Rust optimization
        CARGO_BUILD_JOBS = toString config.nix.settings.max-jobs;
      };

      # Essential system packages for optimization
      systemPackages = with pkgs; [
        # Nix tools
        nix-tree        # Explore Nix store dependencies
        nix-diff        # Compare Nix derivations
        nix-top         # Monitor Nix builds
        
        # System monitoring
        htop
        iotop
        
        # Storage tools
        ncdu            # Disk usage analyzer
        compsize        # Compression ratio analyzer (Btrfs)
      ];
    };
  };
}