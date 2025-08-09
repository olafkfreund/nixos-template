# Hardware Auto-Optimization Guide

The NixOS template includes intelligent hardware detection that automatically optimizes system configuration based on detected hardware capabilities. This eliminates the need for manual hardware-specific tuning in most cases.

## Overview

The auto-optimization module automatically detects:

- **Memory capacity** (RAM in GB)
- **CPU cores** and architecture (Intel/AMD)
- **GPU type** (NVIDIA, AMD, Intel)
- **Storage type** (SSD vs HDD)
- **Platform type** (Laptop vs Desktop)
- **Power capabilities** (Battery presence)

Based on this detection, it automatically configures:

- Memory management (ZRAM, swappiness, kernel parameters)
- CPU optimization (governor, kernel selection, build parallelism)
- GPU drivers and hardware acceleration
- Storage scheduler and filesystem recommendations
- Power management (laptop-specific optimizations)

## Basic Usage

### Enable Auto-Optimization

```nix
# In your configuration.nix
modules.hardware.autoOptimization = {
  enable = true;
};
```

This enables automatic detection and optimization with sensible defaults.

### Debug Mode

```nix
modules.hardware.autoOptimization = {
  enable = true;
  debug = true;  # Adds hardware detection info commands
};
```

Debug mode provides additional commands:

- `hardware-detection-info` - Detailed detection results
- `hw-info` - Quick hardware summary

## Hardware Detection Examples

### High-Memory Desktop (32GB RAM, 16 cores, NVIDIA GPU, SSD)

**Detected:**

- Memory: 32GB → ZRAM: 10%, Swappiness: 10, Hugepages enabled
- CPU: 16 cores → Performance governor, Latest kernel, Build cores: 8
- GPU: NVIDIA → Hardware acceleration, NVIDIA drivers, VAAPI support
- Storage: SSD → ext4 recommended, discard enabled, noatime
- Platform: Desktop → Aggressive performance settings

**Automatic Configuration:**

```nix
# Applied automatically - no manual configuration needed
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 10;  # Low percentage for high-memory systems
};

powerManagement.cpuFreqGovernor = "performance";
boot.kernelPackages = pkgs.linuxPackages_latest;

nix.settings = {
  cores = 8;           # Capped for stability
  max-jobs = "auto";   # Unlimited for high-memory
};

hardware.graphics.enable = true;
services.xserver.videoDrivers = ["nvidia"];

boot.kernel.sysctl = {
  "vm.swappiness" = 10;
  "vm.nr_hugepages" = 1024;  # Enable hugepages
};
```

### Laptop (8GB RAM, 4 cores, Intel GPU, SSD)

**Detected:**

- Memory: 8GB → ZRAM: 50%, Swappiness: 20
- CPU: 4 cores → Powersave governor, Standard kernel, Limited builds
- GPU: Intel → Intel graphics drivers, hardware acceleration
- Storage: SSD → ext4 recommended, async discard
- Platform: Laptop → Power management, TLP, thermal management

**Automatic Configuration:**

```nix
# Applied automatically
zramSwap = {
  enable = true;
  memoryPercent = 50;  # Higher percentage for lower memory
};

powerManagement.cpuFreqGovernor = "powersave";
boot.kernelPackages = pkgs.linuxPackages;

nix.settings = {
  cores = 4;
  max-jobs = 2;        # Limited for battery life
};

services.xserver.videoDrivers = ["i915"];

# Laptop-specific optimizations
services.tlp.enable = true;
services.power-profiles-daemon.enable = true;
services.thermald.enable = true;

boot.kernelParams = [
  "intel_pstate=active"
  "pcie_aspm=force"    # Aggressive power saving
];
```

### Server (16GB RAM, 8 cores, No GPU, HDD)

**Detected:**

- Memory: 16GB → ZRAM: 25%, Swappiness: 10
- CPU: 8 cores → Ondemand governor, Hardened kernel, Parallel builds
- GPU: None → No graphics acceleration
- Storage: HDD → btrfs recommended, BFQ scheduler
- Platform: Server → Server-optimized settings

**Automatic Configuration:**

```nix
# Applied automatically
zramSwap = {
  enable = true;
  memoryPercent = 25;
};

powerManagement.cpuFreqGovernor = "ondemand";  # Balance perf/efficiency
boot.kernelPackages = pkgs.linuxPackages_hardened;  # Security focus

hardware.graphics.enable = false;  # No GPU acceleration needed

boot.kernelParams = [
  "intel_idle.max_cstate=1"    # Server performance
  "processor.max_cstate=1"
];
```

## Advanced Configuration

### Override Detection

Sometimes hardware detection might be incorrect or you want to force specific settings:

```nix
modules.hardware.autoOptimization = {
  enable = true;

  # Override detected values
  override = {
    memoryGB = 32;        # Force 32GB detection
    cpuCores = 16;        # Force 16 core detection
    isLaptop = false;     # Force desktop optimization
    hasNvidiaGPU = true;  # Force NVIDIA driver installation
    hasSSD = true;        # Force SSD optimizations
  };
};
```

### Selective Optimization

Enable only specific optimization categories:

```nix
modules.hardware.autoOptimization = {
  enable = true;

  detection = {
    enableMemoryOptimization = true;   # ZRAM, swappiness
    enableCpuOptimization = true;      # Governor, kernel, builds
    enableGpuOptimization = false;     # Skip GPU detection
    enableStorageOptimization = true;  # I/O scheduler, filesystem
    enablePlatformOptimization = true; # Laptop/server specifics
  };
};
```

### Development Override

For development environments where you want predictable behavior:

```nix
modules.hardware.autoOptimization = {
  enable = true;
  debug = true;

  # Force development-friendly settings
  override = {
    isLaptop = false;  # Always use desktop optimizations
    memoryGB = 16;     # Consistent memory assumptions
  };

  detection = {
    enablePlatformOptimization = false;  # Skip platform-specific tweaks
  };
};
```

## Interaction with Other Modules

### Power Management Module

Auto-optimization works alongside the existing power management module:

```nix
modules = {
  # Existing power management
  hardware.power-management = {
    enable = true;
    profile = "desktop";
    cpuGovernor = "ondemand";  # This takes precedence
  };

  # Auto-optimization supplements this
  hardware.autoOptimization = {
    enable = true;
    detection = {
      enableCpuOptimization = false;  # Don't override manual governor
      enableMemoryOptimization = true;  # Still optimize memory
    };
  };
};
```

### Gaming Module

For gaming systems, auto-optimization enhances performance:

```nix
modules = {
  gaming.steam.enable = true;

  hardware.autoOptimization = {
    enable = true;
    # Gaming systems benefit from all optimizations
  };
};

# Result: Automatically detects high-performance hardware and optimizes for:
# - Maximum CPU performance
# - GPU hardware acceleration
# - Low-latency memory management
# - SSD optimizations for fast game loading
```

## Hardware Detection Commands

### Quick Hardware Info

```bash
$ hw-info
🔍 Quick Hardware Info
====================
Memory: 16GB | CPU: 8 cores | Desktop | SSD
```

### Detailed Detection Results (Debug Mode)

```bash
$ hardware-detection-info
🔍 Hardware Detection Results
============================

💾 Memory: 16 GB
🏗️  CPU Cores: 8
💻 Is Laptop: No
🖥️  Has NVIDIA GPU: Yes
🖥️  Has AMD GPU: No
🖥️  Has Intel GPU: No
💿 Has SSD: Yes

⚙️  Applied Optimizations:
  ZRAM: 25% of RAM
  CPU Governor: performance
  Build Cores: 8
  Build Jobs: auto
  Kernel Package: linuxPackages_latest

📋 Hardware Info File: /etc/hardware-optimization-info
```

### Hardware Detection Debug Data

Debug mode creates `/etc/hardware-detection-debug.json` with complete detection data:

```json
{
  "detection": {
    "memoryGB": 16,
    "cpuCores": 8,
    "hasNvidiaGPU": true,
    "hasAMDGPU": false,
    "hasIntelGPU": false,
    "hasSSD": true,
    "isLaptop": false
  },
  "optimizations": {
    "memory": {
      "zramPercent": 25,
      "swappiness": 10
    },
    "cpu": {
      "governor": "performance",
      "buildCores": 8,
      "buildJobs": "auto"
    }
  },
  "overrides": {}
}
```

## Filesystem Optimization Recommendations

The auto-optimization module provides filesystem recommendations in `/etc/hardware-optimization-info`:

```bash
$ cat /etc/hardware-optimization-info
# Hardware-optimized defaults for new filesystem creation:
# Storage type: SSD
# Recommended filesystem: ext4
# Recommended scheduler: none
# Recommended mount options: noatime,discard=async
```

**Note:** This doesn't change existing filesystems - it provides guidance for new installations or additional drives.

## Troubleshooting

### Hardware Not Detected Correctly

1. **Enable debug mode** to see detection results:

   ```nix
   modules.hardware.autoOptimization.debug = true;
   ```

1. **Use overrides** to force correct detection:

   ```nix
   modules.hardware.autoOptimization.override = {
     hasNvidiaGPU = true;  # Force if not detected
   };
   ```

### Optimization Conflicts

If auto-optimization conflicts with manual settings:

1. **Disable specific optimizations:**

   ```nix
   modules.hardware.autoOptimization.detection = {
     enableCpuOptimization = false;  # Keep manual CPU settings
   };
   ```

1. **Check priority** - manual settings in your configuration take precedence over auto-optimization defaults.

### Performance Issues

For performance-critical systems, consider:

1. **Override to high-performance settings:**

   ```nix
   modules.hardware.autoOptimization.override = {
     memoryGB = 64;  # Force high-memory optimizations
     cpuCores = 32;  # Force high-core optimizations
   };
   ```

1. **Disable conservative optimizations:**

   ```nix
   modules.hardware.autoOptimization.detection = {
     enablePlatformOptimization = false;  # Skip laptop power-saving
   };
   ```

## Integration Examples

### Template Configurations

All template configurations can benefit from auto-optimization:

```nix
# hosts/any-template/configuration.nix
{
  imports = [ /* standard imports */ ];

  # Enable for all templates
  modules.hardware.autoOptimization.enable = true;

  # Template-specific overrides as needed
}
```

### VM Configurations

Virtual machines benefit from optimization too:

```nix
# hosts/vm-template/configuration.nix
modules.hardware.autoOptimization = {
  enable = true;
  override = {
    isLaptop = false;  # VMs are typically server-like
    hasSSD = true;     # Most VMs use SSD-backed storage
  };
};
```

## Benefits

✅ **Zero Configuration** - Works out of the box with sensible defaults
✅ **Automatic Optimization** - Detects hardware and applies best practices
✅ **Performance Tuning** - Optimizes for detected hardware capabilities
✅ **Power Efficiency** - Laptop systems get battery-optimized settings
✅ **Build Performance** - Optimizes Nix build parallelism for hardware
✅ **Storage Optimization** - SSD vs HDD aware configurations
✅ **Debug Support** - Tools to verify detection and troubleshoot issues

The auto-optimization module makes NixOS installations more user-friendly by eliminating the need for manual hardware-specific tuning while still allowing overrides when needed.
