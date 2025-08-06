{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.gpu.amd;
  gpuCfg = config.modules.hardware.gpu;
  isDesktop = builtins.elem gpuCfg.profile [ "desktop" "gaming" ];
  isCompute = builtins.elem gpuCfg.profile [ "ai-compute" "server-compute" ];
in
{
  options.modules.hardware.gpu.amd = {
    enable = lib.mkEnableOption "AMD GPU support";
    
    # GPU model selection for specific optimizations
    model = lib.mkOption {
      type = lib.types.enum [ "auto" "rdna3" "rdna2" "rdna1" "vega" "polaris" "legacy" ];
      default = "auto";
      description = "AMD GPU architecture for specific optimizations";
    };
    
    # Desktop-specific options
    gaming = {
      enable = lib.mkEnableOption "gaming optimizations";
      vulkan = lib.mkEnableOption "Vulkan API support" // { default = true; };
      opengl = lib.mkEnableOption "OpenGL optimizations" // { default = true; };
    };
    
    # AI/Compute options
    compute = {
      enable = lib.mkEnableOption "compute/AI optimizations";
      rocm = lib.mkEnableOption "ROCm platform support" // { default = true; };
      openCL = lib.mkEnableOption "OpenCL support" // { default = true; };
      hip = lib.mkEnableOption "HIP runtime support" // { default = true; };
    };
    
    # Overclocking and power management
    powerManagement = {
      enable = lib.mkEnableOption "AMD GPU power management" // { default = true; };
      profile = lib.mkOption {
        type = lib.types.enum [ "auto" "low" "high" "manual" ];
        default = "auto";
        description = "Power management profile";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable AMD GPU kernel modules
    boot = {
      kernelModules = [ "amdgpu" ];
      
      # Kernel parameters for AMD GPUs
      kernelParams = [
        # Enable AMD GPU support
        "amdgpu.si_support=1"
        "amdgpu.cik_support=1"
        "radeon.si_support=0"
        "radeon.cik_support=0"
        
        # IOMMU support for compute workloads
        "amd_iommu=on"
        "iommu=pt"
      ] ++ lib.optionals (cfg.powerManagement.profile == "high") [
        # High performance mode
        "amdgpu.dpm=1"
        "amdgpu.powerplay=1"
      ] ++ lib.optionals isCompute [
        # Compute optimizations
        "amdgpu.vm_fragment_size=9"
        "amdgpu.vm_block_size=9"
      ];
      
      # Blacklist old radeon driver
      blacklistedKernelModules = [ "radeon" ];
    };

    # Hardware acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = isDesktop;
      
      extraPackages = with pkgs; [
        # Mesa drivers
        mesa.drivers
        
        # AMD-specific packages
        amdvlk  # AMD Vulkan driver
      ] ++ lib.optionals cfg.gaming.vulkan [
        # Vulkan support
        vulkan-loader
        vulkan-validation-layers
        vulkan-tools
      ] ++ lib.optionals cfg.compute.rocm [
        # ROCm platform
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
    };

    # Desktop gaming configuration
    environment.systemPackages = lib.mkIf isDesktop (with pkgs; [
      # AMD tools
      radeontop      # GPU monitoring
      amdgpu-top     # Modern AMD GPU monitor
      
      # Graphics utilities
      mesa-demos     # OpenGL demos
      vulkan-tools   # Vulkan utilities
      glxinfo        # OpenGL info
    ] ++ lib.optionals cfg.gaming.enable [
      # Gaming tools
      mangohud       # Gaming overlay
      gamemode       # Gaming optimizations
    ]);

    # AI/Compute configuration
    environment.systemPackages = lib.mkIf isCompute (with pkgs; [
      # ROCm platform
      rocm-opencl-icd
      rocm-opencl-runtime
      
      # Development tools
      clinfo         # OpenCL info
      rocm-smi       # ROCm system management
      
      # AI frameworks (examples)
      # pytorch-rocm
      # tensorflow-rocm
    ] ++ lib.optionals cfg.compute.hip [
      # HIP runtime
      hip
      rocm-device-libs
    ]);

    # ROCm configuration for AI workloads
    systemd.tmpfiles.rules = lib.mkIf (cfg.compute.enable && cfg.compute.rocm) [
      "d /dev/dri 0755 root root"
      "c /dev/kfd 0666 root root - 511:0"
    ];

    # Udev rules for ROCm
    services.udev.extraRules = lib.mkIf (cfg.compute.enable && cfg.compute.rocm) ''
      # ROCm device permissions
      SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0666"
      KERNEL=="kfd", GROUP="render", MODE="0666"
    '';

    # Environment variables
    environment.sessionVariables = lib.mkMerge [
      # Common AMD variables
      {
        # Force AMD GPU usage
        DRI_PRIME = "1";
        
        # AMD-specific optimizations
        RADV_PERFTEST = lib.mkIf cfg.gaming.vulkan "gpl,ngg,sam,rt";
        AMD_VULKAN_ICD = lib.mkIf cfg.gaming.vulkan "RADV";
      }
      
      # Gaming environment
      (lib.mkIf isDesktop {
        # Gaming optimizations
        __GL_SHADER_DISK_CACHE = "1";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
      })
      
      # Compute environment
      (lib.mkIf (cfg.compute.enable && cfg.compute.rocm) {
        # ROCm environment
        ROCM_PATH = "${pkgs.rocm-opencl-runtime}";
        HIP_PATH = "${pkgs.hip}";
        
        # OpenCL
        OPENCL_VENDOR_PATH = "${pkgs.rocm-opencl-icd}/etc/OpenCL/vendors";
      })
    ];

    # Services
    services = {
      # X11 driver
      xserver = lib.mkIf isDesktop {
        enable = lib.mkDefault true;
        videoDrivers = [ "amdgpu" ];
        
        # AMD-specific X11 configuration
        deviceSection = ''
          Option "TearFree" "true"
          Option "DRI" "3"
        '';
      };
    };

    # System groups for GPU access
    users.groups = {
      render = { };  # For compute workloads
      video = { };   # For video acceleration
    };

    # Add users to GPU groups (define users in host config)
    users.users = lib.mkMerge [
      # This will be applied to all normal users
      (lib.genAttrs 
        (builtins.attrNames (lib.filterAttrs (_: user: user.isNormalUser) config.users.users))
        (_: { extraGroups = [ "render" "video" ]; })
      )
    ];

    # Performance optimizations
    boot.kernel.sysctl = lib.mkIf cfg.powerManagement.enable {
      # AMD GPU power management
      "dev.i915.perf_stream_paranoid" = 0;  # Allow GPU profiling
    };

    # Assertions to prevent conflicts
    assertions = [
      {
        assertion = !(cfg.enable && config.modules.hardware.gpu.nvidia.enable && !gpuCfg.multiGpu.enable);
        message = "Cannot enable both AMD and NVIDIA GPUs without multi-GPU configuration";
      }
    ];
  };
}