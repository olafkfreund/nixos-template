# Desktop Environments Guide

This NixOS template supports multiple desktop environments with optimized configurations for different workflows and preferences.

## Available Desktop Environments

### GNOME Desktop

Modern desktop with excellent Wayland support and polished user experience.

**Features:**

- GNOME Shell with extensions support
- Wayland by default with X11 fallback
- GDM display manager
- Integrated applications suite
- Touch-friendly interface
- Excellent accessibility support

**Configuration:**

```nix
modules.desktop.gnome = {
  enable = true;
  # No additional configuration needed for basic setup
};
```

**Best for:** Users who want a polished, modern desktop experience with minimal configuration.

### Hyprland Tiling Window Manager

Modern Wayland compositor with advanced tiling capabilities.

**Features:**

- Dynamic tiling with floating windows
- Waybar status bar with system information
- Dunst notifications
- Highly customizable animations and effects
- Excellent multi-monitor support
- Keyboard-driven workflow

**Basic Configuration:**

```nix
modules.desktop.hyprland = {
  enable = true;
  waybar.enable = true;          # Status bar
  dunst.enable = true;           # Notifications
};
```

### Niri Scrollable Tiling Window Manager

Unique scrollable tiling compositor with innovative column-based layout.

**Features:**

- Scrollable workspaces (infinite horizontal scroll)
- Column-based tiling with flexible window arrangements
- Waybar integration with niri-specific modules
- Dunst notifications with Catppuccin theming
- Mouse wheel workspace switching
- Excellent for ultrawide monitors
- Keyboard and mouse hybrid workflow

**Basic Configuration:**

```nix
modules.desktop.niri = {
  enable = true;
  waybar.enable = true;          # Status bar
  dunst.enable = true;           # Notifications
  scrolling = {
    workspaces = true;           # Enable workspace scrolling
    columns = true;              # Enable column scrolling
  };
};
```

**Advanced Configuration:**

```nix
modules.desktop.niri = {
  enable = true;

  waybar = {
    enable = true;
    position = "top";
    theme = "catppuccin-mocha";
    modules = {
      workspaces = "niri/workspaces";   # Niri-specific workspace module
      window = "niri/window";           # Niri window titles
      clock = true;
      battery = true;
      network = true;
      pulseaudio = true;
      tray = true;
    };
  };

  dunst = {
    enable = true;
    theme = "catppuccin-mocha";
    position = "top-right";
    transparency = 90;
  };

  applications = {
    terminal = "alacritty";      # Default terminal
    launcher = "fuzzel";         # App launcher (recommended for niri)
    browser = "firefox";         # Default browser
    fileManager = "thunar";      # File manager
  };

  scrolling = {
    workspaces = true;           # Enable workspace scrolling
    columns = true;              # Enable column scrolling
    mouse = {
      workspaceScroll = true;    # Mouse wheel workspace switching
      columnScroll = true;       # Mouse wheel column switching
      scrollCooldown = 150;      # Cooldown between scrolls (ms)
    };
  };

  theme = {
    colorScheme = "dark";        # dark, light, auto
    wallpaper = "/path/to/wallpaper.jpg";
    borders = {
      width = 2;
      radius = 8;
      color = "#cba6f7";         # Catppuccin purple
    };
    gaps = {
      inner = 8;
      outer = 16;
    };
  };

  # Window rules for specific applications
  windowRules = [
    {
      match = { app-id = "firefox"; };
      default-column-width = { proportion = 0.75; };
    }
    {
      match = { app-id = "code"; };
      default-column-width = { proportion = 0.6; };
    }
    {
      match = { app-id = "alacritty"; };
      default-column-width = { proportion = 0.4; };
    }
  ];
};
```

**Best for:** Users who want a unique tiling experience with smooth scrolling workflows, especially those with ultrawide monitors.

### Hyprland Advanced Configuration

```nix
modules.desktop.hyprland = {
  enable = true;

  settings = {
    monitors = [
      "DP-1,1920x1080@60,0x0,1"
      "DP-2,1920x1080@60,1920x0,1"
    ];

    appearance = {
      gaps_in = 8;
      gaps_out = 16;
      border_size = 2;
      rounding = 8;
    };

    animations = {
      enable = true;
      speed = 1.0;
    };
  };

  waybar = {
    enable = true;
    position = "top";
    theme = "colorful";
    modules = {
      workspaces = true;
      window = true;
      clock = true;
      battery = true;
      network = true;
      pulseaudio = true;
      tray = true;
    };
  };

  applications = {
    terminal = "alacritty";      # Default terminal
    launcher = "wofi";           # App launcher
    fileManager = "thunar";      # File manager
    browser = "firefox";         # Web browser
  };

  theme = {
    colorScheme = "dark";        # dark, light, auto
    wallpaper = "/path/to/wallpaper.jpg";
    cursor = {
      theme = "Adwaita";
      size = 24;
    };
  };
};
```

**Best for:** Advanced users who prefer keyboard-driven workflows and tiling window management.

### Niri Best Use Cases

**Best for:** Users who want a unique tiling experience with smooth scrolling workflows, especially those with ultrawide monitors or multiple displays.

## Desktop Environment Comparison

All three are Wayland-native; the template no longer ships an X11 session.

| Feature            | GNOME       | Hyprland     | Niri              |
| ------------------ | ----------- | ------------ | ----------------- |
| **Learning Curve** | Easy        | Advanced     | Moderate          |
| **Customization**  | Limited     | Complete     | High              |
| **Resource Usage** | Moderate    | Light        | Very Light        |
| **Touch Support**  | Excellent   | None         | None              |
| **Gaming**         | Good        | Good         | Good              |
| **Configured via** | dconf       | Home Manager | Home Manager      |
| **Unique Feature** | Polished UX | Animations   | Scrollable Tiling |

## Where the configuration lives

GNOME is configured through the NixOS module (`modules.desktop.gnome`) and
dconf. Hyprland and niri are configured through **Home Manager**, so a user can
override a single binding without replacing the whole file:

```nix
# Hyprland — home/profiles/hyprland.nix
wayland.windowManager.hyprland.settings = {
  "$mod" = "SUPER";
  bind = [ "$mod, Q, exec, alacritty" ];
};

# niri — home/profiles/niri.nix, via the niri-flake module
programs.niri.settings.binds = with config.lib.niri.actions; {
  "Mod+T".action = spawn "alacritty";
};
```

Earlier versions wrote `/etc/hypr/hyprland.conf` and `/etc/niri/config.kdl` from
inline Nix strings. Those were system-wide, so nothing could be overridden per
user, and a config language embedded in a Nix string gets no LSP and no
formatter.

niri has no module in nixpkgs or home-manager, which is why
[niri-flake](https://github.com/sodiboo/niri-flake) is an input.

## Configuration Guide

### Choosing a Desktop Environment

Edit your host configuration file (e.g., `hosts/your-hostname/configuration.nix`):

```nix
modules.desktop = {
  # Choose ONE desktop environment
  gnome.enable = true;
  # hyprland.enable = true;
  # niri.enable = true;

  # Common desktop modules
  audio.enable = true;
  fonts.enable = true;
  graphics.enable = true;
};
```

### Home Manager Integration

Each desktop environment includes Home Manager configurations for user-specific settings.

**GNOME Home Configuration:**

```nix
# Import GNOME profile
imports = [ ../../../home/profiles/gnome.nix ];
```

**Hyprland Home Configuration:**

```nix
# Import Hyprland profile
imports = [ ../../../home/profiles/hyprland.nix ];
```

**Niri Home Configuration:**

```nix
# Import Niri profile
imports = [ ../../../home/profiles/niri.nix ];
```

### Multiple Users

Different users can have different desktop preferences:

```nix
# System configuration - enable multiple environments
modules.desktop = {
  gnome.enable = true;
  hyprland.enable = true;  # Both available at login
  niri.enable = true;      # Three desktop environments
};

# User 1 - GNOME preference
home-manager.users.alice = {
  imports = [ ./home/profiles/gnome.nix ];
};

# User 2 - Hyprland preference
home-manager.users.bob = {
  imports = [ ./home/profiles/hyprland.nix ];
};

# User 3 - Niri preference
home-manager.users.charlie = {
  imports = [ ./home/profiles/niri.nix ];
};
```

## Desktop-Specific Features

### GNOME Features

**Extensions:**

- Dash to Dock
- User Themes
- AppIndicator Support
- Vitals (system monitoring)
- Blur My Shell
- Clipboard Indicator

**Applications:**

- Nautilus file manager
- GNOME Terminal
- Text Editor (gedit replacement)
- GNOME Calculator, Calendar, Weather
- GNOME Tweaks for advanced settings

**Keyboard Shortcuts:**

- `Super` - Activities overview
- `Super + L` - Lock screen
- `Ctrl + Alt + T` - Terminal
- `Alt + F2` - Run command

### Hyprland Features

**Tiling Management:**

- Dynamic tiling layouts
- Floating window support
- Multi-monitor workspaces
- Tabbed and stacked layouts

**Status Bar (Waybar):**

- Workspace indicators
- Window titles
- System tray
- Battery, network, audio status
- Clock and calendar

**Applications:**

- Alacritty/Kitty terminal
- Wofi application launcher
- Thunar file manager
- Grim screenshot tool
- Swaylock screen locker

**Key Bindings:**

- `Super + Q` - Terminal
- `Super + C` - Close window
- `Super + R` - App launcher
- `Super + 1-9` - Switch workspace
- `Super + Shift + 1-9` - Move window to workspace

### Niri Features

**Scrollable Tiling:**

- Infinite horizontal workspace scrolling
- Column-based tiling with flexible arrangements
- Mouse wheel workspace navigation
- Smooth scrolling animations
- No traditional workspace limits

**Column Management:**

- Dynamic column widths (preset, proportional, or fixed)
- Window stacking within columns
- Consume/expel windows between columns
- Column reordering and movement

**Status Bar (Waybar with Niri modules):**

- Scrollable workspace indicators
- Current window titles
- Niri-specific workspace information
- Standard system information (battery, network, audio)
- System tray integration

**Applications:**

- Alacritty/Foot terminal (lightweight Wayland terminals)
- Fuzzel launcher (optimized for niri)
- Thunar/Nautilus file manager
- Grim/Slurp screenshot tools
- Swaylock screen locker

**Unique Key Bindings:**

- `Super + T` - Terminal
- `Super + D` - App launcher
- `Super + Q` - Close window
- `Super + Page_Up/Page_Down` - Scroll workspaces
- `Super + Mouse_Wheel` - Scroll workspaces
- `Super + Left/Right` - Navigate columns
- `Super + Ctrl + Left/Right` - Move column
- `Super + F` - Maximize column
- `Super + Shift + F` - Fullscreen window
- `Super + R` - Switch column preset width
- `Super + Comma/Period` - Consume/expel window

**Window Rules:**

- App-specific column widths
- Default window positioning
- Floating window rules
- Focus management

## Troubleshooting

### Display Issues

**GNOME:**

- GNOME 50 is Wayland-only; there is no X11 session to fall back to
- Use GNOME Tweaks for display settings
- Check for conflicting extensions

**Hyprland:**

- Check the monitor setting in `wayland.windowManager.hyprland.settings`
- Verify graphics drivers are loaded
- Check Waybar configuration for display issues

**Niri:**

- Check niri configuration in `~/.config/niri/config.kdl`
- Verify Wayland graphics drivers are loaded
- Check `niri msg --help` for debugging commands
- Use `niri msg action toggle-debug-tint` for visual debugging

### Performance Optimization

**GNOME:**

- Disable animations in GNOME Tweaks
- Limit number of active extensions
- Reduce the number of active extensions

**Hyprland:**

- Disable animations for better performance
- Reduce blur effects
- Optimize monitor refresh rates

**Niri:**

- Scrolling is already optimized and lightweight
- Adjust scroll cooldown for better responsiveness
- Use fewer columns for older hardware
- Disable window shadows if needed

### Application Integration

**Theme Consistency:**

- Install both GTK and Qt theme packages
- Set consistent cursor and icon themes
- Configure XDG desktop portals

**Font Rendering:**

- Enable font antialiasing
- Install complete font families
- Configure font hinting

## Managing Desktop Environments

### Commands

```bash
# List available desktop environments
just list-desktops

# Test desktop configuration
just test-desktop gnome
just test-desktop niri

# Build specific configuration
just build example-desktop

# Switch desktop environment (requires configuration change)
just switch

# Niri-specific commands
just test-niri           # Test Niri configuration
just niri-reload         # Reload Niri config (if running)
just niri-keys           # Show keybindings reference
just niri-debug          # Toggle debug tinting
just niri-config-info    # Show config paths and commands
```

### Switching Between Desktops

To switch desktop environments:

1. Edit your host configuration
1. Disable current desktop (`enable = false`)
1. Enable new desktop (`enable = true`)
1. Rebuild system (`just switch`)
1. Reboot for clean session

### Concurrent Desktop Support

You can enable multiple desktop environments simultaneously:

```nix
modules.desktop = {
  gnome.enable = true;
  hyprland.enable = true;
  niri.enable = true;
};
```

Users can choose at the login screen, but this increases system resource usage.

## Best Practices

### Performance

- Only enable one desktop environment per system
- Use appropriate graphics drivers
- Configure power management for laptops

### Security

- Keep desktop environments updated
- Use strong screen lock passwords
- Configure automatic screen locking

### Backup

- Export desktop settings before major changes
- Document custom configurations
- Test configurations before deployment

### Development

- Use desktop-appropriate development tools
- Configure version control integration
- Set up proper terminal emulators

## Getting Help

1. Check desktop-specific logs:
   - GNOME: `journalctl --user -u gnome-session`
   - Hyprland: Check Hyprland logs in terminal

1. Verify configuration:
   - `nix flake check` - Validate flake
   - `just test-desktop [name]` - Test specific desktop

1. Community resources:
   - NixOS Discourse for NixOS-specific issues
   - Desktop-specific documentation and forums
   - Home Manager documentation for user configs
