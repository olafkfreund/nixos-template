{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.gpu.nvidia;
  gpuCfg = config.modules.hardware.gpu;
  isDesktop = builtins.elem gpuCfg.profile [ "desktop" "gaming" ];
  isCompute = builtins.elem gpuCfg.profile [ "ai-compute" "server-compute" ];
in
{
  options.modules.hardware.gpu.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";

    # Driver selection
    driver = lib.mkOption {
      type = lib.types.enum [ "stable" "beta" "production" "legacy_470" "legacy_390" "open" ];
      default = "stable";
      description = "NVIDIA driver version to use";
    };

    # Hardware configuration
    hardware = {
      # GPU model for specific optimizations  
      model = lib.mkOption {
        type = lib.types.enum [ "auto" "rtx40" "rtx30" "rtx20" "gtx16" "gtx10" "legacy" ];
        default = "auto";
        description = "NVIDIA GPU generation for optimizations";
      };

      # Multi-GPU configuration
      sli = lib.mkEnableOption "SLI/NVLink support";

      # Power limits
      powerLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Power limit in watts (null for default)";
      };
    };

    # Desktop/Gaming options
    gaming = {
      enable = lib.mkEnableOption "gaming optimizations";
      gsync = lib.mkEnableOption "G-SYNC support";
      rtx = lib.mkEnableOption "RTX features (ray tracing, DLSS)";
      nvenc = lib.mkEnableOption "NVENC video encoding";
      prime = {
        enable = lib.mkEnableOption "PRIME support for hybrid graphics";
        offload = lib.mkEnableOption "PRIME offload mode" // { default = true; };
        sync = lib.mkEnableOption "PRIME sync mode";
        # Bus IDs are auto-detected but can be manually set
        nvidiaBusId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "NVIDIA GPU bus ID (e.g., PCI:1:0:0)";
        };
        intelBusId = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Intel GPU bus ID (e.g., PCI:0:2:0)";
        };
      };
    };

    # AI/Compute options
    compute = {
      enable = lib.mkEnableOption "compute/AI optimizations";
      cuda = lib.mkEnableOption "CUDA support" // { default = true; };
      cudnn = lib.mkEnableOption "cuDNN support" // { default = true; };
      tensorrt = lib.mkEnableOption "TensorRT support";
      opencl = lib.mkEnableOption "OpenCL support";
      containers = lib.mkEnableOption "NVIDIA Container Runtime support";
      mig = lib.mkEnableOption "Multi-Instance GPU support";
    };

    # Professional/Creator options
    professional = {
      enable = lib.mkEnableOption "professional/creator optimizations";
      nvv4l2 = lib.mkEnableOption "Video4Linux2 support";
      broadcast = lib.mkEnableOption "NVIDIA Broadcast SDK";
    };
  };

  config = lib.mkIf cfg.enable {
    # NVIDIA driver configuration
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      # Driver version
      package =
        if cfg.driver == "stable" then config.boot.kernelPackages.nvidiaPackages.stable
        else if cfg.driver == "beta" then config.boot.kernelPackages.nvidiaPackages.beta
        else if cfg.driver == "production" then config.boot.kernelPackages.nvidiaPackages.production
        else if cfg.driver == "legacy_470" then config.boot.kernelPackages.nvidiaPackages.legacy_470
        else if cfg.driver == "legacy_390" then config.boot.kernelPackages.nvidiaPackages.legacy_390
        else if cfg.driver == "open" then config.boot.kernelPackages.nvidiaPackages.open
        else config.boot.kernelPackages.nvidiaPackages.stable;

      # Enable modesetting (required for Wayland)
      modesetting.enable = true;

      # Power management
      powerManagement = {
        enable = lib.mkDefault true;
        finegrained = lib.mkDefault false;
      };

      # Open source kernel modules (for RTX 30+ series)
      open = cfg.driver == "open";

      # NVIDIA settings access for users
      nvidiaSettings = isDesktop;

      # PRIME configuration for hybrid graphics
      prime = lib.mkIf cfg.gaming.prime.enable {
        offload = lib.mkIf cfg.gaming.prime.offload {
          enable = true;
          enableOffloadCmd = true;
        };
        sync.enable = cfg.gaming.prime.sync;

        # Auto-detect or use manual bus IDs
        nvidiaBusId =
          if cfg.gaming.prime.nvidiaBusId != ""
          then cfg.gaming.prime.nvidiaBusId
          else "PCI:1:0:0"; # Common default
        intelBusId =
          if cfg.gaming.prime.intelBusId != ""
          then cfg.gaming.prime.intelBusId
          else "PCI:0:2:0"; # Common default
      };
    };

    # Kernel parameters
    boot.kernelParams = [
      # Enable IOMMU for compute workloads
      "intel_iommu=on"
      "iommu=pt"
    ] ++ lib.optionals isCompute [
      # Compute optimizations
      "nvidia-drm.modeset=1"
    ] ++ lib.optionals cfg.hardware.sli [
      # SLI support
      "nvidia-drm.fbdev=1"
    ];

    # Hardware acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = isDesktop;

      extraPackages = with pkgs; [
        # NVIDIA packages
        nvidia-vaapi-driver # VAAPI support
      ] ++ lib.optionals cfg.gaming.nvenc [
        # Video encoding  
        nv-codec-headers
      ] ++ lib.optionals cfg.compute.cuda [
        # CUDA runtime
        cudatoolkit
      ];
    };

    # System packages for NVIDIA GPU support
    environment.systemPackages = with pkgs; (
      # Desktop packages
      lib.optionals isDesktop [
        # NVIDIA tools
        nvidia-system-monitor-qt # GPU monitoring
        nvtop # Terminal GPU monitor

        # Graphics utilities
        glxinfo # OpenGL info
        vulkan-tools # Vulkan utilities
        nvidia-settings # NVIDIA control panel
      ] ++ lib.optionals (isDesktop && cfg.gaming.enable) [
        # Gaming tools
        mangohud # Gaming overlay
        gamemode # Gaming optimizations
      ] ++
      # AI/Compute packages
      lib.optionals isCompute [
        # CUDA development
        cudatoolkit

        # Monitoring and management
        nvidia-ml-py # Python ML interface
        nvtop # GPU monitoring

        # Development tools
        nsight-compute # CUDA profiler
        nsight-systems # System profiler
      ] ++ lib.optionals (isCompute && cfg.compute.cudnn) [
        # Deep learning
        cudnn
      ] ++ lib.optionals (isCompute && cfg.compute.tensorrt) [
        # TensorRT inference
        # tensorrt
      ] ++ lib.optionals (isCompute && cfg.compute.containers) [
        # Container support
        nvidia-docker
        nvidia-container-toolkit
      ]
    );

    # CUDA and AI framework support
    environment.sessionVariables = lib.mkMerge [
      # Common NVIDIA variables
      {
        # Force NVIDIA GPU usage
        __NV_PRIME_RENDER_OFFLOAD = lib.mkIf cfg.gaming.prime.enable "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      }

      # Gaming environment
      (lib.mkIf isDesktop {
        # Gaming optimizations
        __GL_SHADER_DISK_CACHE = "1";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
        __GL_THREADED_OPTIMIZATIONS = "1";

        # NVENC
        LIBVA_DRIVER_NAME = lib.mkIf cfg.gaming.nvenc "nvidia";
      })

      # Compute environment  
      (lib.mkIf (cfg.compute.enable && cfg.compute.cuda) {
        # CUDA environment
        CUDA_PATH = "${pkgs.cudatoolkit}";
        CUDA_ROOT = "${pkgs.cudatoolkit}";

        # Library paths
        LD_LIBRARY_PATH = "${pkgs.cudatoolkit}/lib:${pkgs.cudatoolkit.lib}/lib";

        # cuDNN
        CUDNN_PATH = lib.mkIf cfg.compute.cudnn "${pkgs.cudnn}";
      })
    ];

    # Container runtime for AI workloads
    virtualisation.docker = lib.mkIf (cfg.compute.enable && cfg.compute.containers) {
      enable = true;
      enableNvidia = true;
    };

    virtualisation.podman = lib.mkIf (cfg.compute.enable && cfg.compute.containers) {
      enable = true;
      enableNvidia = true;
    };

    # System services
    systemd.services = lib.mkMerge [
      # Power management service
      (lib.mkIf (cfg.hardware.powerLimit != null) {
        nvidia-power-limit = {
          description = "Set NVIDIA GPU Power Limit";
          wantedBy = [ "multi-user.target" ];
          after = [ "systemd-modules-load.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            # Wait for nvidia-ml to be available
            sleep 2
            
            # Set power limit using nvidia-smi
            ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl ${toString cfg.hardware.powerLimit} || true
          '';
        };
      })

      # Persistence mode for compute workloads
      (lib.mkIf isCompute {
        nvidia-persistence = {
          description = "NVIDIA Persistence Mode";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "forking";
            PIDFile = "/var/run/nvidia-persistenced/nvidia-persistenced.pid";
            Restart = "always";
            ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-persistenced --verbose";
          };
        };
      })
    ];

    # Udev rules for device permissions
    services.udev.extraRules = ''
      # NVIDIA device permissions
      KERNEL=="nvidia", GROUP="video", MODE="0660"
      KERNEL=="nvidia*", GROUP="video", MODE="0660"
      KERNEL=="nvidia_modeset", GROUP="video", MODE="0660"
      KERNEL=="nvidia_uvm", GROUP="video", MODE="0660"
      KERNEL=="nvidiactl", GROUP="video", MODE="0660"
    '';

    # System groups
    users.groups = {
      video = { }; # For GPU access
      docker = lib.mkIf (cfg.compute.enable && cfg.compute.containers) { };
    };

    # Add users to appropriate groups
    users.users = lib.mkMerge [
      (lib.genAttrs
        (builtins.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users))
        (_: {
          extraGroups = [ "video" ]
            ++ lib.optionals (cfg.compute.enable && cfg.compute.containers) [ "docker" ];
        })
      )
    ];

    # Kernel modules
    boot.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    # Assertions
    assertions = [
      {
        assertion = !(cfg.enable && config.modules.hardware.gpu.amd.enable && !gpuCfg.multiGpu.enable);
        message = "Cannot enable both NVIDIA and AMD GPUs without multi-GPU configuration";
      }
      {
        assertion = !(cfg.gaming.prime.offload && cfg.gaming.prime.sync);
        message = "Cannot enable both PRIME offload and sync modes simultaneously";
      }
    ];
  };
}
