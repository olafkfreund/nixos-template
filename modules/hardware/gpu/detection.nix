{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.gpu;
in
{
  options.modules.hardware.gpu = {
    autoDetect = lib.mkEnableOption "automatic GPU detection and configuration" // { default = true; };

    # Note: Individual GPU enable options are declared in their respective modules
    # (amd.nix, nvidia.nix, intel.nix) - this module only sets them based on detection

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
      pciutils # lspci for GPU detection
      glxinfo # GPU info
      clinfo # OpenCL info
      # GPU monitoring tools can be added per-host as needed
    ];

    # Note: Auto-detection of GPU modules cannot be done during evaluation
    # Users should manually enable the appropriate GPU modules:
    # modules.hardware.gpu.amd.enable = true;
    # modules.hardware.gpu.nvidia.enable = true;
    # modules.hardware.gpu.intel.enable = true;

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
