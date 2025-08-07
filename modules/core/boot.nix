{ config, lib, pkgs, ... }:

{
  boot = {
    # Modern systemd boot loader (recommended for UEFI)
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true; # Keep: users may want GRUB
        configurationLimit = 10;
        editor = false; # Security: disable boot editing
      };
      efi.canTouchEfiVariables = lib.mkDefault true; # Keep: depends on system
      timeout = lib.mkDefault 3; # Keep: users may want different timeout
    };

    # Kernel parameters for better security and performance
    kernelParams = [
      "kernel.yama.ptrace_scope=1"
      "kernel.kptr_restrict=2"
      "kernel.dmesg_restrict=1"
      "mitigations=auto"
    ];

    # Latest kernel (users may prefer LTS)
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Fast tmpfs for /tmp
    tmp.useTmpfs = lib.mkDefault true; # Keep: not everyone wants tmpfs
    tmp.tmpfsSize = "50%";

    # Plymouth disabled by default (keep mkDefault - some hosts may want boot splash)
    plymouth.enable = lib.mkDefault false;
  };
}
