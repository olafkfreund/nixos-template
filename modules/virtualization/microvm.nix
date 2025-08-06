{ config, lib, pkgs, ... }:

let
  cfg = config.modules.virtualization.microvm;
in
{
  options.modules.virtualization.microvm = {
    enable = lib.mkEnableOption "MicroVM optimizations";
    
    minimizeSize = lib.mkEnableOption "aggressive size minimization" // { default = true; };
    
    disableDocumentation = lib.mkEnableOption "disable documentation to save space" // { default = true; };
    
    useMinimalKernel = lib.mkEnableOption "use minimal kernel configuration" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    # Enable guest optimizations with maximum performance focus
    modules.virtualization.guest-optimizations = {
      enable = true;
      disableUnneededServices = true;
      optimizeForSpeed = true;
    };
    
    # Minimal boot configuration
    boot = {
      # Use minimal kernel
      kernelPackages = lib.mkIf cfg.useMinimalKernel (lib.mkDefault pkgs.linuxPackages_latest);
      
      # Minimal initrd
      initrd = {
        # Only include essential modules
        availableKernelModules = [
          "virtio_pci"
          "virtio_blk" 
          "virtio_net"
          "virtio_console"
        ];
        
        # Use systemd for faster boot
        systemd.enable = true;
        verbose = false;
        
        # Compress initrd aggressively
        compressor = "zstd";
        compressorArgs = [ "-19" "-T0" ];
      };
      
      # Optimize kernel for size and speed
      kernelParams = [
        "quiet"
        "loglevel=1"
        "systemd.show_status=false"
        "rd.udev.log_level=1"
        
        # Memory optimizations
        "transparent_hugepage=never"
        "ksm=1"
        
        # Fast boot
        "elevator=noop"
        "clocksource=kvm-clock"
        "no_timer_check"
      ];
      
      # Disable unused subsystems
      blacklistedKernelModules = [
        # Audio
        "snd"
        "soundcore"
        
        # Bluetooth
        "bluetooth"
        "btusb" 
        
        # Wireless
        "cfg80211"
        "mac80211"
        "iwlwifi"
        
        # Graphics (unless needed)
        # "drm"
        # "i915"
        
        # USB (unless needed)
        # "usbcore"
        # "ehci_hcd"
        # "xhci_hcd"
      ];
    };
    
    # Minimal system packages
    environment = {
      # Reduce default packages
      defaultPackages = lib.mkIf cfg.minimizeSize (with pkgs; [
        # Only absolute essentials
        coreutils
        util-linux
        bash
        nano
      ]);
      
      # Minimal system packages
      systemPackages = lib.mkIf cfg.minimizeSize (with pkgs; [
        # Network tools
        iproute2
        iputils
      ]);
      
      # Reduce variables
      variables = {
        EDITOR = "nano";
        PAGER = "cat";
      };
    };
    
    # Disable documentation
    documentation = lib.mkIf cfg.disableDocumentation {
      enable = false;
      man.enable = false;
      info.enable = false;
      nixos.enable = false;
    };
    
    # Minimal services
    services = {
      # Disable unneeded services
      nscd.enable = false;
      
      # Minimal SSH (if needed)
      openssh = {
        enable = lib.mkDefault false;
        settings = lib.mkIf config.services.openssh.enable {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          Protocol = 2;
          Compression = false;
        };
        
        # Minimal host keys
        hostKeys = [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
      
      # Minimal journald
      journald.extraConfig = ''
        Storage=volatile
        RuntimeMaxUse=10M
        SystemMaxUse=20M
        MaxFileSec=1day
        MaxRetentionSec=1week
      '';
    };
    
    # Minimal systemd configuration
    systemd = {
      # Faster timeouts (microvm-specific overrides)
      settings.Manager = {
        DefaultTimeoutStartSec = lib.mkForce "15s";  # Override guest-optimizations
        DefaultTimeoutStopSec = lib.mkForce "5s";
        DefaultDeviceTimeoutSec = lib.mkForce "5s";
      };
      
      # Minimal targets
      targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
      
      # Optimize services
      services = {
        # Faster systemd-udevd
        systemd-udevd.serviceConfig = {
          MountFlags = "slave";
          PrivateMounts = true;
        };
      };
    };
    
    # Disable NSS modules since we're disabling nscd
    system.nssModules = lib.mkForce [];
    
    # Network optimizations
    networking = {
      # Use systemd-networkd
      useNetworkd = true;
      useDHCP = false;
      
      # Disable IPv6 if not needed
      enableIPv6 = lib.mkDefault false;
      
      # Minimal firewall
      firewall = {
        enable = lib.mkDefault true;
        allowPing = true;
        # Only allow essential ports
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };
    };
    
    # Memory optimizations
    systemd.services.systemd-oomd.enable = false;
    
    # Minimal filesystem
    fileSystems = {
      "/" = {
        options = [ "noatime" "nodiratime" "discard" ];
      };
    };
    
    # No swap
    swapDevices = [ ];
    zramSwap.enable = false;
    
    # Minimal users
    users = {
      # No default packages for users
      defaultUserShell = pkgs.bash;
      
      # Minimal user configuration
      users.root = {
        # Disable root account
        hashedPassword = "!";
      };
    };
    
    # Optimize nix store
    nix = {
      # Minimal gc settings
      gc = {
        automatic = true;
        dates = lib.mkForce "daily";  # More frequent than default for minimal VMs
        options = lib.mkForce "--delete-older-than 3d";  # Aggressive cleanup for minimal VMs
      };
      
      # Auto-optimize store more aggressively
      settings = {
        auto-optimise-store = true;
        min-free = lib.mkDefault (1024 * 1024 * 1024); # 1GB default
        max-free = lib.mkDefault (2 * 1024 * 1024 * 1024); # 2GB default
      };
    };
  };
}