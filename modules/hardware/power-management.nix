# Power Management Module
# Unified power management with hardware-specific optimizations
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.hardware.power-management;
in
{
  options.modules.hardware.power-management = {
    enable = mkEnableOption "power management";

    profile = mkOption {
      type = types.enum [ "laptop" "desktop" "server" "workstation" "gaming" ];
      default = "desktop";
      description = "Hardware profile for power management optimization";
    };

    cpuGovernor = mkOption {
      type = types.nullOr (types.enum [ "performance" "powersave" "ondemand" "conservative" "schedutil" ]);
      default = null;
      description = "CPU frequency scaling governor (null for auto-detection based on profile)";
    };

    enableThermalManagement = mkOption {
      type = types.bool;
      default = true;
      description = "Enable thermal management and monitoring";
    };

    laptop = {
      enableBatteryOptimization = mkOption {
        type = types.bool;
        default = cfg.profile == "laptop";
        description = "Enable laptop battery optimization features";
      };

      enableTlp = mkOption {
        type = types.bool;
        default = cfg.profile == "laptop";
        description = "Enable TLP for advanced laptop power management";
      };

      suspendMethod = mkOption {
        type = types.enum [ "suspend" "hibernate" "hybrid-sleep" ];
        default = "suspend";
        description = "Default suspend method for laptops";
      };

      wakeOnLid = mkOption {
        type = types.bool;
        default = true;
        description = "Wake system when laptop lid is opened";
      };
    };

    desktop = {
      enablePerformanceMode = mkOption {
        type = types.bool;
        default = cfg.profile == "desktop" || cfg.profile == "gaming" || cfg.profile == "workstation";
        description = "Enable performance-focused power settings";
      };

      disableUsbAutosuspend = mkOption {
        type = types.bool;
        default = cfg.profile == "desktop" || cfg.profile == "gaming";
        description = "Disable USB autosuspend for better peripheral compatibility";
      };
    };

    server = {
      enableServerOptimizations = mkOption {
        type = types.bool;
        default = cfg.profile == "server";
        description = "Enable server-specific power optimizations";
      };

      disableWakeOnLan = mkOption {
        type = types.bool;
        default = false;
        description = "Disable Wake-on-LAN (enable for remote server management)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Base power management always enabled
    powerManagement = {
      enable = true;

      # CPU frequency scaling governor
      cpuFreqGovernor =
        if cfg.cpuGovernor != null then cfg.cpuGovernor
        else if cfg.profile == "laptop" then "schedutil"
        else if cfg.profile == "server" then "ondemand"
        else if cfg.profile == "gaming" then "performance"
        else "ondemand"; # desktop, workstation default

      # Power buttons and lid switch
      powertop.enable = cfg.profile == "laptop";
    };

    # Services configuration
    services = {
      # Laptop-specific configurations
      tlp = mkIf cfg.laptop.enableTlp {
        enable = true;
        settings = {
          # CPU frequency scaling
          CPU_SCALING_GOVERNOR_ON_AC =
            if cfg.profile == "gaming" then "performance"
            else "ondemand";
          CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

          # CPU energy/performance policy
          CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
          CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

          # CPU boost
          CPU_BOOST_ON_AC = if cfg.profile == "gaming" then 1 else 1;
          CPU_BOOST_ON_BAT = 0;

          # CPU HWP (Hardware P-States)
          CPU_HWP_DYN_BOOST_ON_AC = 1;
          CPU_HWP_DYN_BOOST_ON_BAT = 0;

          # Platform profile
          PLATFORM_PROFILE_ON_AC = "performance";
          PLATFORM_PROFILE_ON_BAT = "low-power";

          # Processor features
          CPU_MIN_PERF_ON_AC = 0;
          CPU_MAX_PERF_ON_AC = 100;
          CPU_MIN_PERF_ON_BAT = 0;
          CPU_MAX_PERF_ON_BAT = 50;

          # Turbo boost switching
          TURBO_BOOST_ON_AC = 1;
          TURBO_BOOST_ON_BAT = 0;

          # Audio power saving
          SOUND_POWER_SAVE_ON_AC = 0;
          SOUND_POWER_SAVE_ON_BAT = 1;

          # WiFi power saving
          WIFI_PWR_ON_AC = "off";
          WIFI_PWR_ON_BAT = "on";

          # Graphics power management
          RADEON_DPM_PERF_LEVEL_ON_AC = "high";
          RADEON_DPM_PERF_LEVEL_ON_BAT = "low";

          # PCIe power management
          PCIE_ASPM_ON_AC = "default";
          PCIE_ASPM_ON_BAT = "powersupersave";

          # USB autosuspend
          USB_AUTOSUSPEND = 1;
          USB_BLACKLIST_BTUSB = 1; # Prevent Bluetooth issues

          # Battery care
          START_CHARGE_THRESH_BAT0 = 75;
          STOP_CHARGE_THRESH_BAT0 = 80;
          RESTORE_DEVICE_STATE_ON_STARTUP = 0;
        };
      };

      # Battery optimization for laptops
      upower = mkIf cfg.laptop.enableBatteryOptimization {
        enable = true;
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
        criticalPowerAction = "Hibernate";
      };

      # Thermal management
      thermald = mkIf cfg.enableThermalManagement {
        enable = mkDefault (cfg.profile == "laptop" || cfg.profile == "workstation");
      };
    };

    # Desktop/Gaming optimizations
    boot.kernel.sysctl = mkIf cfg.desktop.enablePerformanceMode {
      # VM/memory management for performance
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;
      "vm.swappiness" = if cfg.profile == "gaming" then 1 else 10;

      # Network performance
      "net.core.rmem_max" = 536870912;
      "net.core.wmem_max" = 536870912;
      "net.ipv4.tcp_rmem" = "4096 87380 536870912";
      "net.ipv4.tcp_wmem" = "4096 65536 536870912";

      # Gaming-specific optimizations
      "kernel.sched_rt_runtime_us" = mkIf (cfg.profile == "gaming") (-1);
    };

    # Server optimizations
    boot.kernelParams = mkMerge [
      # Laptop-specific kernel parameters
      (mkIf (cfg.profile == "laptop") [
        "acpi_backlight=native"
        "i915.enable_psr=1" # Intel Panel Self Refresh
      ])

      # Gaming-specific parameters
      (mkIf (cfg.profile == "gaming") [
        "mitigations=off" # Disable CPU vulnerability mitigations for performance
        "preempt=full" # Full preemption for low latency
      ])

      # Server parameters
      (mkIf (cfg.profile == "server") [
        "intel_idle.max_cstate=1" # Prevent deep C-states that can cause latency
        "processor.max_cstate=1"
        "idle=poll" # For very low latency requirements
      ])
    ];

    # Hardware-specific service configurations
    services = {
      # Auto CPU frequency scaling
      auto-cpufreq = mkIf (cfg.profile == "laptop" && !cfg.laptop.enableTlp) {
        enable = true;
        settings = {
          battery = {
            governor = "powersave";
            turbo = "never";
          };
          charger = {
            governor = if cfg.profile == "gaming" then "performance" else "ondemand";
            turbo = "auto";
          };
        };
      };

      # Laptop lid and power button handling
      logind = {
        lidSwitch = mkIf (cfg.profile == "laptop") cfg.laptop.suspendMethod;
        lidSwitchExternalPower = mkIf (cfg.profile == "laptop") "ignore";
        extraConfig = mkIf (cfg.profile == "laptop") ''
          HandlePowerKey=suspend
          HandleSuspendKey=suspend
          HandleHibernateKey=hibernate
        '';
      };

      # ACPI events
      acpid = mkIf (cfg.profile == "laptop") {
        enable = true;
      };
    };

    # USB power management
    services.udev.extraRules = mkIf cfg.desktop.disableUsbAutosuspend ''
      # Disable USB autosuspend for input devices to prevent lag
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="*", TEST=="power/control", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1532", ATTR{idProduct}=="*", TEST=="power/control", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="usb", SUBSYSTEMS=="input", TEST=="power/control", ATTR{power/control}="on"
    '';

    # Power monitoring tools
    environment.systemPackages = with pkgs; [
      # Common power monitoring
      powertop
      acpi

      # Laptop-specific tools
    ] ++ optionals (cfg.profile == "laptop") [
      tlp
      brightnessctl

      # Battery information
      upower
    ] ++ optionals (cfg.profile == "server") [
      # Server monitoring
      lm_sensors
      smartmontools
    ] ++ optionals cfg.enableThermalManagement [
      lm_sensors
    ];

    # Hardware monitoring
    hardware.sensor.iio.enable = mkDefault (cfg.profile == "laptop");

    # Firmware updates (mainly for laptops)
    services.fwupd.enable = mkDefault (cfg.profile == "laptop");

    # Profile-specific optimizations
    programs = {
      # Laptop-specific programs
      light.enable = cfg.profile == "laptop";
    };

    # ZRAM for memory-constrained systems
    zramSwap = mkIf (cfg.profile == "laptop") {
      enable = mkDefault true;
      algorithm = "zstd";
      memoryPercent = 50;
    };
  };
}
