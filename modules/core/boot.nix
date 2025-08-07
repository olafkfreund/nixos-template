{ config, lib, pkgs, ... }:

{
  boot = {
    # Modern systemd boot loader (recommended for UEFI)
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 10; # Limit boot entries
        editor = false; # Disable editing for security
      };
      efi.canTouchEfiVariables = lib.mkDefault true;
      timeout = lib.mkDefault 3;
    };

    # Kernel parameters for better security and performance
    kernelParams = [
      # Security
      "kernel.yama.ptrace_scope=1"
      "kernel.kptr_restrict=2"
      "kernel.dmesg_restrict=1"

      # Performance
      "mitigations=auto"
    ];

    # Enable latest kernel by default
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Temporary file systems
    tmp = {
      useTmpfs = lib.mkDefault true;
      tmpfsSize = "50%";
    };

    # tmpfs automatically cleans on boot

    # Plymouth for graphical boot (optional)
    plymouth = {
      enable = lib.mkDefault false;
      theme = "breeze";
    };
  };
}
