# Power Management Guide

This NixOS template includes comprehensive power management optimized for different hardware types:
laptops, desktops, workstations, and servers.

## Overview

The power management system automatically detects your hardware type and applies appropriate optimizations:

- **Laptops**: Battery optimization, thermal management, power saving
- **Desktops**: Performance-focused settings, gaming optimizations
- **Workstations**: Balanced performance with multi-monitor support
- **Servers**: Reliability and performance for headless operation

## Hardware Detection

The template includes automatic hardware detection to determine the best power profile:

```bash
# Detect hardware type automatically
just detect-hardware

# Or use the script directly
./scripts/detect-hardware.sh
```

**Detection Methods:**

- Chassis type identification (DMI information)
- Battery presence and configuration
- Display setup (built-in vs external)
- Network interfaces (WiFi presence)
- CPU and memory specifications
- Audio hardware configuration

## Power Profiles

### Laptop Profile

Optimized for mobile computing with focus on battery life:

**Features:**

- TLP (Linux Advanced Power Management)
- Battery charge thresholds (75-80%)
- CPU frequency scaling (powersave on battery)
- WiFi power saving
- Display brightness management
- Suspend/hibernate support

**Configuration:**

```nix
modules.hardware.power-management = {
  enable = true;
  profile = "laptop";

  laptop = {
    enableBatteryOptimization = true;
    enableTlp = true;
    suspendMethod = "suspend";  # or "hibernate", "hybrid-sleep"
    wakeOnLid = true;
  };
};
```

**Key Settings:**

- CPU governor: `schedutil` (balanced)
- USB autosuspend: enabled
- PCIe ASPM: `powersupersave` on battery
- Audio power saving: enabled on battery
- Graphics: reduced performance on battery

### Desktop Profile

Performance-focused configuration for desktop systems:

**Features:**

- Performance CPU scaling
- Disabled USB autosuspend (better for peripherals)
- Optimized memory management
- Network performance tuning
- No battery management

**Configuration:**

```nix
modules.hardware.power-management = {
  enable = true;
  profile = "desktop";

  desktop = {
    enablePerformanceMode = true;
    disableUsbAutosuspend = true;
  };
};
```

**Key Settings:**

- CPU governor: `ondemand`
- VM swappiness: 10 (less swapping)
- Network buffers: increased for performance
- USB devices: no autosuspend

### Workstation Profile

Balanced settings for professional workstations:

**Features:**

- Performance optimization
- Multi-monitor support considerations
- Professional application support
- Development-friendly settings

**Configuration:**

```nix
modules.hardware.power-management = {
  enable = true;
  profile = "workstation";

  desktop = {
    enablePerformanceMode = true;
    disableUsbAutosuspend = true;
  };
};
```

### Server Profile

Optimized for reliability and consistent performance:

**Features:**

- Consistent performance (no deep C-states)
- Network optimization
- Thermal monitoring
- No power saving features that affect latency

**Configuration:**

```nix
modules.hardware.power-management = {
  enable = true;
  profile = "server";

  server = {
    enableServerOptimizations = true;
    disableWakeOnLan = false;  # Keep for remote management
  };
};
```

**Key Settings:**

- CPU governor: `ondemand`
- C-states: limited to prevent latency
- Network: optimized for throughput
- No sleep/suspend modes

### Gaming Profile

Special performance mode for gaming systems:

**Configuration:**

```nix
modules.hardware.power-management = {
  enable = true;
  profile = "gaming";
  cpuGovernor = "performance";  # Maximum performance

  desktop = {
    enablePerformanceMode = true;
    disableUsbAutosuspend = true;
  };
};
```

**Key Settings:**

- CPU governor: `performance`
- VM swappiness: 1 (minimal swapping)
- CPU mitigations: disabled for performance
- Preemption: full for low latency
- RT scheduling: unlimited

## Hardware-Specific Templates

The template includes pre-configured host templates for different hardware types:

### Laptop Template

```bash
# Copy laptop template for new host
cp -r hosts/laptop-template hosts/my-laptop
```

**Includes:**

- Laptop-optimized power management
- GNOME desktop (good power management)
- Battery monitoring services
- WiFi and Bluetooth support
- Automatic brightness adjustment
- Suspend/resume handling

### Desktop Template

```bash
# Copy desktop template for new host
cp -r hosts/desktop-template hosts/my-desktop
```

**Includes:**

- Performance-optimized settings
- Full desktop environment (GNOME/KDE)
- Gaming support (Steam, GameMode)
- Development tools
- Virtualization support
- Multi-monitor configurations

### Server Template

```bash
# Copy server template for new host
cp -r hosts/server-template hosts/my-server
```

**Includes:**

- Headless configuration (no desktop)
- SSH server with hardening
- System monitoring (Prometheus)
- Container support (Podman)
- Security hardening
- Logging and audit configuration

## Setup Script Integration

The setup scripts automatically detect hardware and apply appropriate templates:

```bash
# Quick setup with automatic hardware detection
./scripts/quick-setup.sh

# Full setup with hardware detection and customization options
./scripts/nixos-setup.sh
```

**Hardware Detection Features:**

- Automatic profile selection
- Template recommendation
- Desktop environment suggestions
- Memory-based optimizations

## Manual Configuration

### Enabling Power Management

Add to your host configuration:

```nix
{
  imports = [
    ../../modules/hardware/power-management.nix
  ];

  modules.hardware.power-management = {
    enable = true;
    profile = "laptop";  # laptop, desktop, server, workstation, gaming
    enableThermalManagement = true;
  };
}
```

### Custom CPU Governor

Override the automatic CPU governor selection:

```nix
modules.hardware.power-management = {
  cpuGovernor = "performance";  # performance, powersave, ondemand, conservative, schedutil
};
```

### Laptop-Specific Settings

```nix
modules.hardware.power-management = {
  laptop = {
    enableBatteryOptimization = true;
    enableTlp = true;
    suspendMethod = "suspend";  # suspend, hibernate, hybrid-sleep
    wakeOnLid = true;
  };
};
```

### Desktop Performance Tuning

```nix
modules.hardware.power-management = {
  desktop = {
    enablePerformanceMode = true;
    disableUsbAutosuspend = true;  # Better for gaming mice/keyboards
  };
};
```

### Server Optimizations

```nix
modules.hardware.power-management = {
  server = {
    enableServerOptimizations = true;
    disableWakeOnLan = false;  # Keep enabled for remote management
  };
};
```

## TLP Configuration

For laptops, TLP provides advanced power management:

### Battery Care Settings

```nix
services.tlp.settings = {
  # Battery charge thresholds
  START_CHARGE_THRESH_BAT0 = 75;
  STOP_CHARGE_THRESH_BAT0 = 80;

  # CPU frequency scaling
  CPU_SCALING_GOVERNOR_ON_AC = "performance";
  CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

  # Platform profiles
  PLATFORM_PROFILE_ON_AC = "performance";
  PLATFORM_PROFILE_ON_BAT = "low-power";
};
```

### WiFi Power Management

```nix
services.tlp.settings = {
  WIFI_PWR_ON_AC = "off";   # No power saving when plugged in
  WIFI_PWR_ON_BAT = "on";   # Enable power saving on battery
};
```

## Thermal Management

### Automatic Thermal Control

```nix
services.thermald = {
  enable = true;
  adaptive = true;
};
```

### Custom Thermal Policies

```nix
services.thermald = {
  enable = true;
  configFile = pkgs.writeText "thermal-conf.xml" ''
    <?xml version="1.0"?>
    <ThermalConfiguration>
      <Platform>
        <Name>Generic Laptop</Name>
        <ProductName>*</ProductName>
        <Preference>QUIET</Preference>
      </Platform>
    </ThermalConfiguration>
  '';
};
```

## Monitoring and Debugging

### Check Current Power Settings

```bash
# CPU frequency and governor
cat /proc/cpuinfo | grep MHz
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Battery information (laptops)
acpi -b
upower -i /org/freedesktop/UPower/devices/battery_BAT0

# TLP status (laptops)
sudo tlp-stat

# Thermal information
sensors
cat /proc/cpuinfo | grep MHz
```

### Monitor Power Consumption

```bash
# PowerTOP analysis
sudo powertop

# Battery drain analysis (laptops)
sudo tlp-stat -b

# CPU frequency monitoring
watch -n1 "cat /proc/cpuinfo | grep MHz"
```

### Debugging Power Issues

```bash
# Check systemd power management
systemctl status systemd-logind

# Check TLP service (laptops)
systemctl status tlp

# Check thermald (if enabled)
systemctl status thermald

# View power-related journal logs
journalctl -u tlp
journalctl -u thermald
journalctl -u systemd-logind
```

## Performance Tuning

### Gaming Optimizations

```nix
# Gaming-specific kernel parameters
boot.kernelParams = [
  "mitigations=off"      # Disable CPU vulnerability mitigations
  "preempt=full"         # Full preemption for low latency
];

# Gaming-specific sysctl settings
boot.kernel.sysctl = {
  "kernel.sched_rt_runtime_us" = -1;  # Unlimited RT scheduling
  "vm.swappiness" = 1;                # Minimal swapping
};
```

### Server Performance

```nix
# Server-specific kernel parameters
boot.kernelParams = [
  "intel_idle.max_cstate=1"    # Prevent deep sleep states
  "processor.max_cstate=1"
];

# Network performance tuning
boot.kernel.sysctl = {
  "net.core.rmem_max" = 134217728;
  "net.core.wmem_max" = 134217728;
  "net.ipv4.tcp_rmem" = "4096 87380 134217728";
  "net.ipv4.tcp_wmem" = "4096 65536 134217728";
};
```

### Memory Management

```nix
# Desktop/workstation memory settings
boot.kernel.sysctl = {
  "vm.dirty_ratio" = 15;            # Faster writeback
  "vm.dirty_background_ratio" = 5;
  "vm.swappiness" = 10;             # Reduce swapping
};

# Server memory settings
boot.kernel.sysctl = {
  "vm.dirty_ratio" = 15;
  "vm.dirty_background_ratio" = 5;
  "vm.swappiness" = 10;
  "vm.vfs_cache_pressure" = 50;     # Keep filesystem cache
};
```

## Common Issues and Solutions

### High CPU Usage

```bash
# Check CPU governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Set performance governor temporarily
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Poor Battery Life (Laptops)

```bash
# Analyze power consumption
sudo powertop --auto-tune

# Check TLP configuration
sudo tlp-stat -c

# Monitor power draw
sudo powertop --time=60
```

### Thermal Throttling

```bash
# Monitor CPU temperature
watch sensors

# Check thermal zones
ls /sys/class/thermal/thermal_zone*/

# View thermal events
dmesg | grep thermal
```

### Suspend/Resume Issues (Laptops)

```bash
# Check suspend configuration
systemctl status systemd-suspend

# View suspend/resume logs
journalctl -b | grep -i suspend
journalctl -b | grep -i resume

# Test suspend manually
systemctl suspend
```

## Advanced Configuration

### Custom Power Profiles

Create custom power profiles for specific use cases:

```nix
# Custom gaming profile
modules.hardware.power-management = {
  enable = true;
  profile = "gaming";

  # Override specific settings
  desktop = {
    enablePerformanceMode = true;
    disableUsbAutosuspend = true;
  };

  # Custom kernel parameters
  boot.kernelParams = [
    "isolcpus=2,3"  # Isolate CPU cores for gaming
  ];
};
```

### Per-Application Power Management

```nix
# Gaming-specific environment variables
environment.sessionVariables = {
  # Graphics optimizations
  DXVK_HUD = "compiler,memory";
  RADV_PERFTEST = "gpl";

  # CPU scheduling
  WINE_CPU_TOPOLOGY = "4:2";
};
```

### Wake-on-LAN Configuration

```nix
# Enable Wake-on-LAN for remote servers
networking.interfaces.enp0s31f6.wakeOnLan.enable = true;

# Or via systemd
systemd.network.networks."10-wired" = {
  matchConfig.Name = "enp0s31f6";
  wakeOnLan.enable = true;
};
```

This comprehensive power management system ensures optimal performance and efficiency across all hardware types while providing easy customization for specific needs.
