# Zero-Configuration NixOS Guide

This template now provides **zero-configuration hardware optimization** that automatically detects and optimizes your system without manual tuning.

## Overview

The NixOS template includes intelligent systems that eliminate manual configuration:

- 🔍 **Hardware Auto-Detection** - Automatically detects memory, CPU, GPU, storage, and platform
- ⚙️ **Smart Optimization** - Applies optimal settings based on detected hardware
- 🏗️ **Build Optimization** - Optimizes Nix builds for your hardware capabilities
- 🔋 **Power Management** - Laptop vs desktop optimizations automatically applied
- 🛠️ **Debug Tools** - Commands to verify detection and troubleshoot issues

## Quick Start

### Enable Auto-Optimization

Add this single line to any configuration to enable zero-configuration optimization:

```nix
hardware.autoOptimization.enable = true;
```

That's it! Your system will automatically:

✅ Detect hardware capabilities
✅ Optimize memory management (ZRAM, swap)  
✅ Configure CPU governor and kernel selection
✅ Install appropriate GPU drivers
✅ Apply storage-specific optimizations
✅ Enable platform-appropriate power management

### Verify It's Working

After enabling, you can check what was detected:

```bash
# Quick hardware summary
hw-info

# Detailed detection results (with debug = true)
hardware-detection-info
```

## Template Integration

All template configurations can benefit from auto-optimization:

### Desktop/Workstation Templates

```nix
# hosts/desktop-template/configuration.nix
{
  imports = [ /* standard imports */ ];
  
  # Enable zero-configuration optimization
  hardware.autoOptimization.enable = true;
  
  # Rest of your configuration...
}
```

**Result**: Automatically optimized for high-performance desktop use with appropriate GPU drivers and performance settings.

### Laptop Templates  

```nix
# hosts/laptop-template/configuration.nix  
{
  imports = [ /* standard imports */ ];
  
  # Enable with laptop-aware optimizations
  hardware.autoOptimization = {
    enable = true;
    debug = true;  # Enable battery monitoring commands
  };
}
```

**Result**: Automatically enables power management, TLP, thermal management, and battery-optimized settings.

### Server Templates

```nix
# hosts/server-template/configuration.nix
{
  imports = [ /* standard imports */ ];
  
  # Server optimization with performance focus  
  hardware.autoOptimization = {
    enable = true;
    detection = {
      enablePlatformOptimization = false;  # Skip laptop power-saving
    };
  };
}
```

**Result**: Optimized for server workloads with appropriate kernel, memory management, and build parallelism.

## Hardware-Specific Examples

### High-Performance Gaming Rig

**Detected**: 32GB RAM, 16 CPU cores, NVIDIA RTX GPU, NVMe SSD

**Automatic Optimization**:
- ZRAM: 10% (low overhead for high memory)
- CPU: Performance governor, latest kernel
- GPU: NVIDIA drivers, hardware acceleration, VAAPI
- Storage: ext4 recommended, async discard
- Build: 8 parallel cores, unlimited jobs

### Developer Laptop

**Detected**: 16GB RAM, 8 CPU cores, Intel GPU, SSD, Battery

**Automatic Optimization**:
- ZRAM: 25% (balanced for medium memory)
- CPU: Powersave governor, standard kernel  
- GPU: Intel drivers, hardware acceleration
- Storage: SSD optimizations
- Power: TLP, thermal management, battery thresholds
- Build: Limited parallelism for battery life

### Home Server

**Detected**: 8GB RAM, 4 CPU cores, No GPU, HDD

**Automatic Optimization**:
- ZRAM: 50% (compensate for lower memory)
- CPU: Ondemand governor, hardened kernel
- GPU: No graphics acceleration
- Storage: btrfs recommended, BFQ scheduler
- Build: Conservative parallelism

## Advanced Configuration

### Override Detection

When hardware detection is incorrect:

```nix
hardware.autoOptimization = {
  enable = true;
  override = {
    memoryGB = 32;        # Force high-memory optimizations
    cpuCores = 16;        # Force high-performance CPU settings
    hasNvidiaGPU = true;  # Force NVIDIA drivers even if not detected
    hasSSD = true;        # Force SSD optimizations
    isLaptop = false;     # Force desktop optimization
  };
};
```

### Selective Optimization

Enable only specific optimization categories:

```nix
hardware.autoOptimization = {
  enable = true;
  detection = {
    enableMemoryOptimization = true;   # ZRAM, swappiness optimization
    enableCpuOptimization = true;      # Governor, kernel, build settings
    enableGpuOptimization = false;     # Skip GPU detection/drivers
    enableStorageOptimization = true;  # I/O scheduler optimization  
    enablePlatformOptimization = true; # Laptop vs desktop differences
  };
};
```

### Debug Mode

Enable detailed hardware detection information:

```nix
hardware.autoOptimization = {
  enable = true;
  debug = true;  # Enables hardware-detection-info command
};
```

## Integration with Existing Modules

Auto-optimization works alongside existing template modules:

### With Power Management

```nix
modules = {
  # Manual power management (takes precedence)
  hardware.power-management = {
    enable = true;
    cpuGovernor = "ondemand";  # This overrides auto-detection
  };
  
  # Auto-optimization (supplements manual settings)
  hardware.autoOptimization = {
    enable = true;
    detection = {
      enableCpuOptimization = false;  # Don't override manual governor
      enableMemoryOptimization = true;  # Still optimize memory
    };
  };
};
```

### With Gaming Module

```nix
modules = {
  gaming.steam.enable = true;
  
  hardware.autoOptimization.enable = true;
  # Result: Automatically detects gaming hardware and optimizes for:
  # - Maximum CPU performance
  # - GPU hardware acceleration  
  # - Low-latency memory management
  # - Fast SSD game loading
};
```

## Troubleshooting

### Hardware Not Detected

1. **Check detection results**:
   ```bash
   hardware-detection-info
   ```

2. **Override incorrect detection**:
   ```nix
   hardware.autoOptimization.override.hasNvidiaGPU = true;
   ```

### Configuration Conflicts

If auto-optimization conflicts with manual settings:

```nix
# Disable conflicting optimizations
hardware.autoOptimization.detection.enableCpuOptimization = false;
```

Manual settings always take precedence over auto-optimization defaults.

### Performance Issues

For performance-critical systems:

```nix
hardware.autoOptimization.override = {
  memoryGB = 64;  # Force high-memory optimizations
  cpuCores = 32;  # Force high-performance settings
  isLaptop = false;  # Skip power-saving optimizations
};
```

## Migration from Manual Configuration

### Before (Manual Configuration)
```nix
# Manual hardware configuration
zramSwap.enable = true;
zramSwap.memoryPercent = 25;
powerManagement.cpuFreqGovernor = "performance";
hardware.graphics.enable = true;
services.xserver.videoDrivers = ["nvidia"];
boot.kernelParams = ["transparent_hugepage=madvise"];
nix.settings.cores = 8;
# ... dozens more manual settings
```

### After (Zero Configuration)
```nix
# Automatic hardware optimization
hardware.autoOptimization.enable = true;
# That's it! All the above settings applied automatically based on detected hardware
```

## Benefits Summary

✅ **Zero Configuration** - Works out of the box with optimal settings
✅ **Hardware Agnostic** - Same configuration works on different hardware  
✅ **Performance Optimized** - Automatically tuned for your specific hardware
✅ **Power Efficient** - Laptop systems get battery-optimized configurations
✅ **Build Performance** - Nix builds optimized for your CPU and memory
✅ **Storage Aware** - Different optimizations for SSD vs HDD systems
✅ **Override Capable** - Can override detection when needed
✅ **Debug Friendly** - Tools to verify and troubleshoot detection
✅ **Module Compatible** - Works with all existing template modules

The zero-configuration approach makes NixOS accessible to users without deep hardware knowledge while maintaining the flexibility that power users expect.

## See Also

- [Hardware Auto-Optimization Guide](./HARDWARE-AUTO-OPTIMIZATION.md) - Detailed technical documentation
- [System Identification Guide](./SYSTEM-IDENTIFICATION.md) - System metadata and naming
- [Profile System Guide](./PROFILE-SYSTEM.md) - Home Manager profile architecture