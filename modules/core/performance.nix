# Performance Optimizations Module
# Implements expert-recommended system performance tuning
# Based on NixOS performance best practices and hardware detection

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.core.performance;
  
  # Detect hardware characteristics for performance tuning
  hwDetection = config.modules.hardware.detection;
  
  # Determine optimal settings based on detected hardware
  memoryClass = if hwDetection.memoryGB >= 32 then "high"
                else if hwDetection.memoryGB >= 16 then "medium"  
                else if hwDetection.memoryGB >= 8 then "low"
                else "minimal";
                
  storageClass = if hwDetection.hasNVMe then "nvme"
                 else if hwDetection.hasSSD then "ssd"
                 else "hdd";
                
  cpuClass = if hwDetection.cpuCores >= 16 then "high"
             else if hwDetection.cpuCores >= 8 then "medium"
             else if hwDetection.cpuCores >= 4 then "low"
             else "minimal";
in
{
  options.modules.core.performance = {
    enable = mkEnableOption "system performance optimizations";
    
    profile = mkOption {
      type = types.enum [ "desktop" "server" "laptop" "gaming" "minimal" ];
      default = "desktop";
      description = "Performance profile to optimize for";
    };
    
    aggressiveOptimizations = mkEnableOption "aggressive performance optimizations (may reduce stability)";
    
    networkOptimizations = mkEnableOption "network performance optimizations";
    
    kernelOptimizations = mkEnableOption "kernel performance tuning";
    
    buildOptimizations = mkEnableOption "build system performance optimizations";
  };

  config = mkIf cfg.enable {
    
    # Kernel performance tuning
    boot.kernel.sysctl = mkMerge [
      # Base performance settings
      {
        # Memory management optimizations
        "vm.swappiness" = mkDefault (
          if memoryClass == "high" then 1
          else if memoryClass == "medium" then 5
          else if memoryClass == "low" then 10
          else 20
        );
        
        "vm.vfs_cache_pressure" = mkDefault (
          if memoryClass == "high" then 10
          else if memoryClass == "medium" then 25
          else 50
        );
        
        "vm.dirty_ratio" = mkDefault (
          if storageClass == "nvme" then 20
          else if storageClass == "ssd" then 15
          else 10
        );
        
        "vm.dirty_background_ratio" = mkDefault (
          if storageClass == "nvme" then 10
          else if storageClass == "ssd" then 5
          else 3
        );
        
        # Reduce memory fragmentation
        "vm.min_free_kbytes" = mkDefault (65536 * (hwDetection.memoryGB / 4));
        
        # File system performance
        "fs.file-max" = mkDefault 2097152;
        "fs.inotify.max_user_watches" = mkDefault 1048576;
        
        # Process scheduling
        "kernel.sched_autogroup_enabled" = mkDefault 1;
        "kernel.sched_cfs_bandwidth_slice_us" = mkDefault 3000;
      }
      
      # Network optimizations (when enabled)
      (mkIf cfg.networkOptimizations {
        # TCP performance tuning
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        
        # Network buffer sizes
        "net.core.rmem_default" = 262144;
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_default" = 262144;
        "net.core.wmem_max" = 16777216;
        
        # TCP window scaling
        "net.ipv4.tcp_window_scaling" = 1;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 65536 16777216";
        
        # TCP optimization
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.core.netdev_max_backlog" = 30000;
        
        # Reduce TIME_WAIT sockets
        "net.ipv4.tcp_fin_timeout" = 10;
        "net.ipv4.tcp_tw_reuse" = 1;
      })
      
      # Aggressive optimizations (when enabled)
      (mkIf cfg.aggressiveOptimizations {
        # More aggressive memory management
        "vm.page-cluster" = 0; # Disable page clustering for SSD
        "vm.oom_kill_allocating_task" = 1;
        
        # CPU scheduler optimizations
        "kernel.sched_migration_cost_ns" = 50000;
        "kernel.sched_min_granularity_ns" = 1000000;
        "kernel.sched_wakeup_granularity_ns" = 2000000;
        
        # I/O scheduler optimizations
        "kernel.io_delay_type" = 0; # No delay for modern hardware
      })
    ];

    # Build system optimizations
    nix.settings = mkIf cfg.buildOptimizations {
      # Parallel builds based on CPU cores
      max-jobs = mkDefault (
        if cpuClass == "high" then 16
        else if cpuClass == "medium" then 8
        else if cpuClass == "low" then 4
        else 2
      );
      
      cores = 0; # Use all available cores for each job
      
      # Build optimization features
      keep-outputs = true;        # Enable incremental builds
      keep-derivations = true;    # Reuse build artifacts
      auto-optimise-store = true; # Deduplicate store paths
      
      # Download optimization
      http-connections = mkDefault (
        if cfg.networkOptimizations then 25 else 5
      );
      
      # Cache optimization
      narinfo-cache-positive-ttl = 432000; # 5 days
      narinfo-cache-negative-ttl = 86400;  # 1 day
      
      # Faster builds with substitution
      substitute = true;
      builders-use-substitutes = true;
      
      # Memory management for builds
      max-silent-time = 3600; # 1 hour for large builds
    };
    
    # Profile-specific optimizations
    boot.kernelParams = mkMerge [
      # Base kernel parameters
      [
        # Enable modern CPU features
        "intel_pstate=active"
        "amd_pstate=active"
      ]
      
      # Gaming profile optimizations
      (mkIf (cfg.profile == "gaming") [
        # Reduce input latency
        "processor.max_cstate=1"
        "intel_idle.max_cstate=1"
        # Disable CPU mitigations for performance (security tradeoff)
        "mitigations=off"
        # Gaming-specific optimizations
        "threadirqs"
        "split_lock_detect=off"
      ])
      
      # Server profile optimizations  
      (mkIf (cfg.profile == "server") [
        # Server workload optimization
        "elevator=mq-deadline"
        "numa_balancing=enable"
        # Better for multi-threaded server workloads
        "transparent_hugepage=madvise"
      ])
      
      # Laptop profile optimizations
      (mkIf (cfg.profile == "laptop") [
        # Power efficiency
        "intel_pstate=powersave"
        "amd_pstate=powersave"
        # Better battery life
        "pcie_aspm=force"
      ])
    ];

    # Storage optimizations based on detected hardware
    services.fstrim = mkIf (hwDetection.hasSSD || hwDetection.hasNVMe) {
      enable = true;
      interval = "weekly";
    };

    # I/O scheduler optimization
    services.udev.extraRules = mkIf cfg.kernelOptimizations ''
      # Set optimal I/O schedulers based on storage type
      ${optionalString hwDetection.hasNVMe ''
        ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
      ''}
      
      ${optionalString hwDetection.hasSSD ''
        ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      ''}
      
      ${optionalString (!hwDetection.hasSSD && !hwDetection.hasNVMe) ''
        ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
      ''}
    '';

    # Systemd optimizations
    systemd = {
      # Faster service startup
      services.systemd-udev-settle.enable = false; # Skip waiting for udev
      
      # Optimize systemd itself
      extraConfig = ''
        DefaultTimeoutStartSec=30s
        DefaultTimeoutStopSec=10s
        DefaultRestartSec=100ms
        DefaultLimitNOFILE=1048576
        DefaultLimitMEMLOCK=infinity
      '';
    };

    # Tmpfs optimizations for better performance
    boot.tmp = {
      useTmpfs = mkDefault (memoryClass != "minimal");
      tmpfsSize = mkDefault (
        if memoryClass == "high" then "50%"
        else if memoryClass == "medium" then "25%"
        else if memoryClass == "low" then "15%"
        else "10%"
      );
    };

    # Zram configuration based on available memory
    zramSwap = mkIf (memoryClass != "high") {
      enable = true;
      memoryPercent = mkDefault (
        if memoryClass == "medium" then 25
        else if memoryClass == "low" then 50
        else 75
      );
      algorithm = "zstd"; # Better compression than lz4
      priority = 5; # Higher priority than disk swap
    };

    # Hardware-specific optimizations
    powerManagement = {
      # CPU frequency scaling
      cpuFreqGovernor = mkDefault (
        if cfg.profile == "gaming" then "performance"
        else if cfg.profile == "server" then "performance"  
        else if cfg.profile == "laptop" then "powersave"
        else "schedutil" # Adaptive for desktop
      );
    };

    # Warnings for potentially problematic settings
    warnings = 
      optional (cfg.aggressiveOptimizations && cfg.profile != "gaming")
        "Aggressive optimizations enabled outside of gaming profile may cause instability" ++
      optional (cfg.profile == "gaming" && elem "mitigations=off" config.boot.kernelParams)
        "Security mitigations disabled for gaming performance - this reduces system security";
        
    assertions = [
      {
        assertion = cfg.enable -> config.modules.hardware.detection.enable;
        message = "Performance module requires hardware detection to be enabled";
      }
    ];
  };
}