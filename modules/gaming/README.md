# Gaming Configuration

This directory contains NixOS modules for gaming optimization and Steam configuration. The modules provide comprehensive gaming support with performance optimizations, hardware support, and compatibility tools.

## Modules

### steam.nix

Comprehensive Steam gaming platform configuration with system optimizations.

#### Features

**Core Gaming**:
- Steam platform with latest features
- Proton-GE for enhanced Windows game compatibility
- GameMode for system optimization during gaming
- MangoHud for performance monitoring and overlay

**Hardware Support**:
- Steam Controller and Steam Deck support
- Gaming controller support (Xbox, PlayStation, Nintendo)
- Proper udev rules for gaming peripherals
- Audio optimizations for low-latency gaming

**Performance Optimizations**:
- Kernel parameters tuned for gaming
- Real-time scheduling permissions
- Memory management optimizations
- GPU-specific optimizations (NVIDIA/AMD)

**Network Features**:
- Steam Remote Play support
- Local Network Game Transfers
- Firewall configuration for Steam services

#### Configuration

Enable Steam gaming in your host configuration:

```nix
# Enable Steam gaming module
modules.gaming.steam = {
  enable = true;
  
  # Performance optimizations
  performance = {
    gamemode = true;
    mangohud = true;
    optimizations = true;
  };
  
  # Compatibility tools
  compattools = {
    proton-ge = true;
    luxtorpeda = false;  # Native Linux engines
  };
  
  # Hardware support
  hardware.steam-hardware = true;
  
  # Network features
  remotePlay.enable = true;
  localNetworkGameTransfers.enable = true;
};
```

#### Advanced Options

**GameScope Session**:
```nix
modules.gaming.steam = {
  gamescopeSession = {
    enable = true;
    args = [ "--rt" "--prefer-vk-device" "8086:9bc4" ];
  };
};
```

**Custom Performance Settings**:
```nix
modules.gaming.steam = {
  performance.optimizations = true;
  extraPackages = with pkgs; [
    protontricks
    steamtinkerlaunch
    gamemode
  ];
};
```

**Audio Configuration**:
- Automatic PipeWire optimization for gaming
- PulseAudio configuration fallback
- Low-latency audio settings

**System Optimizations**:
- CPU governor management
- I/O scheduler optimization
- Memory management tuning
- Process priority adjustments

#### Included Tools

**Performance Monitoring**:
- MangoHud - Performance overlay
- GameMode - System optimization
- System monitoring and notifications

**Compatibility**:
- Proton-GE - Enhanced Windows compatibility
- Wine - Additional Windows game support
- Steam Runtime - Consistent gaming environment

**Development**:
- Protontricks - Proton prefix management
- Steam Tinker Launch - Advanced game tweaking
- Steam debugging tools

#### User Setup

After enabling the module:

1. **Add user to steam group** (automatic for normal users):
   ```bash
   # Users are automatically added to required groups
   ```

2. **Launch Steam**:
   ```bash
   steam
   ```

3. **Enable Proton** in Steam settings:
   - Steam > Settings > Steam Play
   - Enable Steam Play for supported titles
   - Enable Steam Play for all other titles

4. **Use GameMode**:
   ```bash
   # GameMode activates automatically with Steam games
   # Manual activation:
   gamemoded
   ```

#### Gaming Fonts

The module installs additional fonts for better game compatibility:
- Liberation fonts
- DejaVu fonts
- Source Han fonts
- CJK language support

#### Controller Support

Automatic support for:
- Steam Controller
- Xbox controllers (all generations)
- PlayStation controllers (DualShock 4, DualSense)
- Nintendo Switch Pro Controller
- Generic HID controllers

#### Troubleshooting

**Steam not launching**:
```bash
# Check Steam runtime
steam --debug

# Reset Steam configuration
rm -rf ~/.steam/steam
```

**Games not starting**:
```bash
# Check Proton logs
export PROTON_LOG=1
# Game logs in ~/.steam/steam/logs/

# Try different Proton versions
# Steam > Properties > Compatibility > Force specific version
```

**Performance issues**:
```bash
# Check GameMode status
gamemoded -s

# Monitor with MangoHud
mangohud steam

# Check system resources
htop
nvidia-smi  # For NVIDIA GPUs
```

**Controller issues**:
```bash
# Test controller detection
jstest /dev/input/js0

# Check Steam controller support
steam://controller
```

#### Environment Variables

The module sets optimized environment variables:
- `PROTON_USE_WINED3D=0` - Use DXVK instead of WineD3D
- `DXVK_LOG_LEVEL=none` - Reduce DXVK logging
- `MANGOHUD=1` - Enable MangoHud overlay
- Various OpenGL and Vulkan optimizations

#### Integration

**Desktop Environment Integration**:
- Proper MIME types for game files
- Steam overlay support
- Notification integration

**System Integration**:
- Automatic service management
- Resource optimization
- Hardware detection

## User Groups

Users are automatically added to required groups:
- `steam` - Steam platform access
- `gamemode` - GameMode privileges
- `audio` - Audio device access
- `input` - Controller access

## Performance Notes

The gaming configuration includes:
- Kernel optimizations for low latency
- Audio system tuning
- GPU driver optimizations  
- Network stack improvements
- File system performance tweaks

For optimal gaming performance:
1. Use a fast SSD for game storage
2. Ensure adequate RAM (16GB+ recommended)
3. Use a modern GPU with Vulkan support
4. Configure appropriate screen refresh rates

## Updates

Gaming packages are managed through Nixpkgs:
```bash
# Update system including gaming packages
sudo nixos-rebuild switch

# Update Steam client
# Steam updates automatically through its client
```