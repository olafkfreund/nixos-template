# Laptop Template Home Manager Configuration
# Uses shared profiles optimized for mobile computing
{ config, pkgs, ... }:

{
  # Import shared Home Manager profiles
  imports = [
    ../../home/profiles/base.nix # Base configuration with git, bash, etc.
    ../../home/profiles/desktop.nix # Desktop applications and GUI tools
    ../../home/profiles/development.nix # Development tools
  ];

  # Host-specific user info (overrides base profile defaults)
  home = {
    username = "user";
    homeDirectory = "/home/user";
  };

  # Override git configuration with host-specific details
  programs.git = {
    userName = "Laptop User";
    userEmail = "laptop-user@example.com";
  };

  # Laptop-specific environment variables
  home.sessionVariables = {
    # Optimize for laptop usage
    EDITOR = "code";
    BROWSER = "firefox";

    # Power efficiency for laptops
    GDK_SCALE = "1.25"; # For HiDPI laptop screens
    QT_SCALE_FACTOR = "1.25";

    # Laptop-optimized Wayland support
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Laptop-specific packages (lightweight alternatives and mobile tools)
  home.packages = with pkgs; [
    # Laptop productivity tools
    calibre # E-book management for reading on the go
    zotero # Research management

    # Mobile development
    android-tools
    scrcpy # Android screen mirroring

    # Network tools for mobile use
    wireshark
    nmap

    # Battery and power management utilities
    powertop
    acpi

    # Synchronization tools for mobile work
    syncthing
    rclone

    # Lightweight alternatives
    mousepad # Lightweight text editor
    thunar # Lightweight file manager
  ];

  # Laptop-optimized bash aliases (extends base profile)
  programs.bash.shellAliases = {
    # Battery and power management
    "battery" = "acpi -b";
    "powersave" = "sudo powertop --auto-tune";
    "thermal" = "cat /sys/class/thermal/thermal_zone*/temp | awk '{print $1/1000\"°C\"}'";

    # Network utilities for mobile work
    "wifi" = "nmcli dev wifi";
    "wificonnect" = "nmcli dev wifi connect";
    "netinfo" = "ip addr show";

    # Mobile-friendly shortcuts
    "suspend" = "systemctl suspend";
    "hibernate" = "systemctl hibernate";

    # Screen brightness (if using brightnessctl)
    "bright+" = "brightnessctl set +10%";
    "bright-" = "brightnessctl set 10%-";

    # Quick file synchronization
    "syncup" = "rclone sync ~/Documents remote:Documents";
    "syncdown" = "rclone sync remote:Documents ~/Documents";
  };

  # Laptop-specific bash functions
  programs.bash.bashrcExtra = ''
    # Laptop management functions

    # WiFi connection helper
    wifi-connect() {
      if [ $# -eq 0 ]; then
        nmcli dev wifi list
      else
        nmcli dev wifi connect "$1"
      fi
    }

    # Battery status with notification
    battery-notify() {
      local battery_level=$(acpi -b | grep -P -o '[0-9]+(?=%)')
      if [ "$battery_level" -le 20 ]; then
        notify-send "Battery Low" "Battery level: $battery_level%"
      fi
    }

    # Toggle power profile
    power-profile() {
      local profile=''${1:-balanced}
      case $profile in
        "performance"|"perf")
          echo "Setting performance profile"
          sudo cpupower frequency-set -g performance
          ;;
        "powersave"|"save")
          echo "Setting powersave profile"
          sudo cpupower frequency-set -g powersave
          ;;
        "balanced"|*)
          echo "Setting balanced profile"
          sudo cpupower frequency-set -g ondemand
          ;;
      esac
    }

    # Quick laptop status
    laptop-status() {
      echo "=== Laptop Status ==="
      echo "Battery: $(acpi -b | cut -d',' -f2)"
      echo "Temperature: $(cat /sys/class/thermal/thermal_zone*/temp | awk '{print $1/1000\"°C\"}' | head -1)"
      echo "WiFi: $(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)"
      echo "Brightness: $(brightnessctl get 2>/dev/null || echo 'N/A')"
    }
  '';

  # Laptop-optimized Git configuration for mobile work
  programs.git.extraConfig = {
    # Laptop-specific Git optimizations
    core.preloadindex = true;
    core.fscache = true;
    gc.auto = 256; # More frequent GC for limited storage

    # Mobile-friendly settings
    credential.helper = "store"; # Store credentials for mobile convenience
    push.default = "simple";
    pull.rebase = true; # Cleaner history for mobile sync
  };
}
