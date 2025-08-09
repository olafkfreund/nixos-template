{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.gpu.intel;
  gpuCfg = config.modules.hardware.gpu;
  isDesktop = builtins.elem gpuCfg.profile [ "desktop" "gaming" ];
  isCompute = builtins.elem gpuCfg.profile [ "ai-compute" "server-compute" ];
in
{
  options.modules.hardware.gpu.intel = {
    enable = lib.mkEnableOption "Intel integrated GPU support";

    # Intel GPU generation
    generation = lib.mkOption {
      type = lib.types.enum [ "auto" "arc" "xe" "iris-xe" "iris-plus" "uhd" "hd" "legacy" ];
      default = "auto";
      description = "Intel GPU generation for specific optimizations";
    };

    # Desktop options
    desktop = {
      enable = lib.mkEnableOption "desktop optimizations" // { default = isDesktop; };
      vaapi = lib.mkEnableOption "VA-API hardware acceleration" // { default = true; };
      vulkan = lib.mkEnableOption "Vulkan API support" // { default = true; };
      opengl = lib.mkEnableOption "OpenGL optimizations" // { default = true; };
    };

    # Compute options (Intel Arc and Xe GPUs)
    compute = {
      enable = lib.mkEnableOption "compute optimizations" // { default = isCompute; };
      oneapi = lib.mkEnableOption "Intel OneAPI support";
      opencl = lib.mkEnableOption "OpenCL support" // { default = true; };
      level_zero = lib.mkEnableOption "Level Zero API support";
    };

    # Power management
    powerManagement = {
      enable = lib.mkEnableOption "Intel GPU power management" // { default = true; };
      rc6 = lib.mkEnableOption "RC6 power saving states" // { default = true; };
      fbc = lib.mkEnableOption "Frame Buffer Compression" // { default = true; };
      psr = lib.mkEnableOption "Panel Self Refresh" // { default = true; };
    };
  };

  config = lib.mkIf cfg.enable {
    # Intel GPU kernel modules and parameters
    boot = {
      kernelModules = [ "i915" ];

      # Kernel parameters for Intel GPUs
      kernelParams = [
        # Enable GuC and HuC firmware loading (for newer GPUs)
        "i915.enable_guc=2"

        # Enable FBC (Frame Buffer Compression)
        "i915.enable_fbc=1"

        # Enable PSR (Panel Self Refresh)
        "i915.enable_psr=1"
      ] ++ lib.optionals cfg.powerManagement.rc6 [
        # RC6 power states
        "i915.enable_rc6=1"
      ] ++ lib.optionals (cfg.generation == "arc" || cfg.generation == "xe") [
        # Intel Arc/Xe specific optimizations
        "i915.force_probe=*"
        "i915.enable_dc=2"
      ] ++ lib.optionals isCompute [
        # Compute workload optimizations
        "i915.preempt_timeout=100"
        "i915.timeslice_duration=1"
      ];

      # Early KMS for Intel
      initrd.kernelModules = [ "i915" ];
    };

    # Hardware acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = isDesktop;

      extraPackages = with pkgs; [
        # Intel media drivers
        intel-media-driver # VAAPI for newer Intel GPUs (Gen 8+)
        libvdpau-va-gl # VDPAU over VA-API

        # Legacy support
        intel-vaapi-driver # VAAPI for older Intel GPUs

        # Vulkan support
        intel-compute-runtime # OpenCL runtime
      ] ++ lib.optionals cfg.desktop.vulkan [
        # Vulkan drivers
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools
      ] ++ lib.optionals (cfg.compute.enable && cfg.compute.oneapi) [
        # Intel OneAPI components
        intel-compute-runtime
        level-zero
      ];

      # 32-bit support for older applications
      extraPackages32 = lib.mkIf isDesktop (with pkgs.pkgsi686Linux; [
        intel-media-driver
        intel-vaapi-driver
      ]);
    };

    # System packages for Intel GPU support
    environment.systemPackages = with pkgs; (
      # Desktop packages
      lib.optionals isDesktop [
        # Intel GPU tools
        intel-gpu-tools # Intel GPU debugging tools
        libva-utils # VA-API utilities (vainfo, etc.)

        # Graphics utilities
        glxinfo # OpenGL info
        vulkan-tools # Vulkan utilities
        mesa-demos # OpenGL demos
      ] ++
      # Compute packages for Intel Arc/Xe
      lib.optionals (cfg.compute.enable && (cfg.generation == "arc" || cfg.generation == "xe")) [
        # Intel compute tools
        intel-compute-runtime
        clinfo # OpenCL info

        # Level Zero tools
        level-zero # Level Zero runtime
      ] ++ lib.optionals (cfg.compute.enable && (cfg.generation == "arc" || cfg.generation == "xe") && cfg.compute.oneapi) [
        # Intel OneAPI toolkit components
        # intel-oneapi-runtime
      ]
    );

    # Environment variables
    environment.sessionVariables = lib.mkMerge [
      # Common Intel variables
      {
        # Hardware acceleration
        LIBVA_DRIVER_NAME = lib.mkIf cfg.desktop.vaapi "iHD"; # Use iHD for newer Intel
        VDPAU_DRIVER = "va_gl";
      }

      # Desktop environment
      (lib.mkIf isDesktop {
        # Mesa optimizations for Intel
        MESA_LOADER_DRIVER_OVERRIDE = "iris"; # Use Iris driver for Gen 8+

        # Vulkan
        VK_ICD_FILENAMES = lib.mkIf cfg.desktop.vulkan
          "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json";
      })

      # Compute environment
      (lib.mkIf cfg.compute.enable {
        # OpenCL
        OPENCL_VENDOR_PATH = "${pkgs.intel-compute-runtime}/etc/OpenCL/vendors";

        # Level Zero
        ZE_ENABLE_PCI_ID_DEVICE_ORDER = lib.mkIf cfg.compute.level_zero "1";
      })
    ];

    # X11 configuration
    services.xserver = lib.mkIf isDesktop {
      enable = lib.mkDefault true;
      videoDrivers = [ "modesetting" ]; # Use modesetting driver for Intel

      # Intel-specific configuration
      deviceSection = ''
        Option "AccelMethod" "glamor"
        Option "DRI" "3"
        Option "TearFree" "true"
      '';

      # Additional options for newer Intel GPUs
      extraConfig = lib.mkIf (cfg.generation == "arc" || cfg.generation == "xe") ''
        Section "OutputClass"
            Identifier "Intel Graphics"
            MatchDriver "i915"
            Driver "modesetting"
            Option "AccelMethod" "glamor"
            Option "DRI" "3"
        EndSection
      '';
    };

    # Intel GPU frequency scaling
    systemd.services.intel-gpu-frequency = lib.mkIf cfg.powerManagement.enable {
      description = "Intel GPU Frequency Management";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Set GPU frequency scaling
        if [ -d /sys/kernel/debug/dri/0 ]; then
          echo "auto" > /sys/kernel/debug/dri/0/i915_ring_freq_table || true
        fi

        # Enable RC6 if available
        if [ -f /sys/class/drm/card0/power/rc6_enable ]; then
          echo 1 > /sys/class/drm/card0/power/rc6_enable || true
        fi
      '';
    };

    # Firmware loading for Intel GPUs
    hardware.firmware = with pkgs; [
      # Intel GPU firmware
      linux-firmware
    ] ++ lib.optionals (cfg.generation == "arc" || cfg.generation == "xe") [
      # Intel Arc/Xe specific firmware
      # intel-gpu-firmware
    ];

    # System groups
    users.groups = {
      video = { }; # For video acceleration
      render = { }; # For compute workloads
    };

    # Add users to appropriate groups
    users.users = lib.mkMerge [
      (lib.genAttrs
        (builtins.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users))
        (_: { extraGroups = [ "video" "render" ]; })
      )
    ];

    # Udev rules for Intel GPU compute access
    services.udev.extraRules = lib.mkIf cfg.compute.enable ''
      # Intel GPU compute device permissions
      SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0666"

      # Intel Arc/Xe specific rules
      SUBSYSTEM=="drm", KERNEL=="card*", ATTRS{vendor}=="0x8086", GROUP="video", MODE="0666"
    '';

    # Performance tuning for Intel Arc/Xe
    boot.kernel.sysctl = lib.mkIf (cfg.generation == "arc" || cfg.generation == "xe") {
      # Memory management for larger GPU memory
      "vm.max_map_count" = 262144;
    };

    # Assertions
    assertions = [
      {
        assertion = cfg.compute.oneapi -> (cfg.generation == "arc" || cfg.generation == "xe");
        message = "Intel OneAPI support is primarily for Intel Arc/Xe GPUs";
      }
    ];
  };
}
