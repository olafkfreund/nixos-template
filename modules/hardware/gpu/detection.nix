{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.gpu;
in
{
  options.modules.hardware.gpu = {
    autoDetect = lib.mkEnableOption "automatic GPU detection and configuration" // { default = true; };
    
    # Manual GPU selection (overrides auto-detection)
    amd.enable = lib.mkEnableOption "AMD GPU support";
    nvidia.enable = lib.mkEnableOption "NVIDIA GPU support"; 
    intel.enable = lib.mkEnableOption "Intel integrated GPU support";
    
    # Workload profiles
    profile = lib.mkOption {
      type = lib.types.enum [ "desktop" "gaming" "ai-compute" "server-compute" ];
      default = "desktop";
      description = "GPU optimization profile";
    };
    
    # Multi-GPU support
    multiGpu = {
      enable = lib.mkEnableOption "multi-GPU configuration";
      primary = lib.mkOption {
        type = lib.types.enum [ "amd" "nvidia" "intel" ];
        default = "nvidia";
        description = "Primary GPU for display output";
      };
    };
  };

  config = lib.mkIf cfg.autoDetect {
    # Hardware detection script
    environment.systemPackages = with pkgs; [
      pciutils  # lspci for GPU detection
      glxinfo   # GPU info
      clinfo    # OpenCL info
      nvtop     # GPU monitoring (works with AMD/NVIDIA)
    ];

    # Auto-detect and enable GPU modules based on hardware
    modules.hardware.gpu = {
      # Detect AMD GPUs
      amd.enable = lib.mkDefault (
        builtins.any (line: 
          lib.hasInfix "AMD" line || 
          lib.hasInfix "ATI" line ||
          lib.hasInfix "Radeon" line
        ) (lib.splitString "\n" (builtins.readFile /proc/cpuinfo || ""))
      );
      
      # Detect NVIDIA GPUs
      nvidia.enable = lib.mkDefault (
        builtins.pathExists /proc/driver/nvidia/version ||
        builtins.any (line: lib.hasInfix "NVIDIA" line) 
          (lib.splitString "\n" (builtins.readFile /proc/cpuinfo || ""))
      );
      
      # Detect Intel integrated graphics
      intel.enable = lib.mkDefault (
        builtins.any (line: 
          lib.hasInfix "Intel" line && 
          (lib.hasInfix "Graphics" line || lib.hasInfix "UHD" line || lib.hasInfix "Iris" line)
        ) (lib.splitString "\n" (builtins.readFile /proc/cpuinfo || ""))
      );
    };

    # GPU detection service
    systemd.services.gpu-detection = {
      description = "GPU Hardware Detection";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Create GPU info file
        mkdir -p /run/gpu-info
        
        # Detect GPUs using lspci
        ${pkgs.pciutils}/bin/lspci -nn | grep -i vga > /run/gpu-info/detected || true
        ${pkgs.pciutils}/bin/lspci -nn | grep -i 3d >> /run/gpu-info/detected || true
        ${pkgs.pciutils}/bin/lspci -nn | grep -i display >> /run/gpu-info/detected || true
        
        # Log detected GPUs
        if [ -s /run/gpu-info/detected ]; then
          echo "Detected GPUs:" >&2
          cat /run/gpu-info/detected >&2
        else
          echo "No discrete GPUs detected" >&2
        fi
      '';
    };

    # Environment variables for GPU detection
    environment.sessionVariables = {
      # Make GPU info available to user sessions
      GPU_INFO_PATH = "/run/gpu-info";
    };
  };
}