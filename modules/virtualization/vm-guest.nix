{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.virtualization.vm-guest;
in
{
  options.modules.virtualization.vm-guest = {
    enable = mkEnableOption "Virtual machine guest optimizations";

    type = mkOption {
      type = types.enum [ "auto" "qemu" "virtualbox" "vmware" "hyperv" "xen" ];
      default = "auto";
      description = "Virtual machine type (auto-detect if possible)";
    };

    optimizations = {
      performance = mkOption {
        type = types.bool;
        default = true;
        description = "Enable performance optimizations for VMs";
      };

      graphics = mkOption {
        type = types.bool;
        default = true;
        description = "Enable graphics acceleration in VMs";
      };

      networking = mkOption {
        type = types.bool;
        default = true;
        description = "Enable VM networking optimizations";
      };

      storage = mkOption {
        type = types.bool;
        default = true;
        description = "Enable storage optimizations for VMs";
      };
    };

    guestTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install VM-specific guest tools";
      };

      clipboard = mkOption {
        type = types.bool;
        default = true;
        description = "Enable clipboard sharing with host";
      };

      folderSharing = mkOption {
        type = types.bool;
        default = true;
        description = "Enable folder sharing capabilities";
      };

      timeSync = mkOption {
        type = types.bool;
        default = true;
        description = "Enable time synchronization with host";
      };
    };

    serial = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable serial console support";
      };

      device = mkOption {
        type = types.str;
        default = "ttyS0";
        description = "Serial device to use";
      };

      baudRate = mkOption {
        type = types.int;
        default = 115200;
        description = "Serial console baud rate";
      };
    };
  };

  config = mkIf cfg.enable {
    # Auto-detect VM type if not specified
    assertions = [
      {
        assertion = cfg.type != "auto" || (
          pathExists "/sys/class/dmi/id/product_name" ||
            pathExists "/sys/devices/virtual/dmi/id/product_name"
        );
        message = "Cannot auto-detect VM type. Please specify manually.";
      }
    ];

    # VM-specific configurations based on detected or specified type
    virtualisation = mkMerge [
      # QEMU/KVM configuration (moved to services section)
      { }

      # VirtualBox configuration
      (mkIf (cfg.type == "virtualbox") {
        virtualbox.guest.enable = cfg.guestTools.enable;
      })

      # VMware configuration
      (mkIf (cfg.type == "vmware") {
        vmware.guest.enable = cfg.guestTools.enable;
      })

      # Hyper-V configuration
      (mkIf (cfg.type == "hyperv") {
        hypervGuest.enable = cfg.guestTools.enable;
      })
    ];

    # Boot optimizations for VMs
    boot = mkMerge [
      {
        # VM-optimized kernel parameters
        kernelParams = [
          "console=tty0"
          "quiet"
          "loglevel=3"
        ] ++ optionals cfg.serial.enable [
          "console=${cfg.serial.device},${toString cfg.serial.baudRate}"
        ];

        # Essential VM kernel modules
        initrd.availableKernelModules = [
          # VirtIO drivers
          "virtio_pci"
          "virtio_blk"
          "virtio_scsi"
          "virtio_net"
          "virtio_balloon"
          "virtio_console"
          "virtio_rng"

          # Storage controllers
          "ahci"
          "ata_piix"
          "mptspi"
          "uhci_hcd"
          "ehci_pci"
          "xhci_pci"
          "sd_mod"
          "sr_mod"

          # Network
          "e1000"
          "e1000e"
          "8139too"
          "pcnet32"
        ];

        # Kernel modules for runtime
        kernelModules = [
          "virtio_console"
        ] ++ optionals (cfg.type == "virtualbox") [
          "vboxguest"
          "vboxsf"
          "vboxvideo"
        ] ++ optionals (cfg.type == "vmware") [
          "vmw_balloon"
          "vmw_pvscsi"
          "vmwgfx"
        ];
      }

      # Boot loader configuration for VMs
      # NOTE: Specific boot loader configuration should be in hardware-configuration.nix
      # This provides only common settings
      {
        loader = {
          # Boot timeout (applies to all boot loaders)
          timeout = mkDefault 3;

          efi.canTouchEfiVariables = mkForce false; # Force safer setting for VMs
        };
      }

      # VM-specific kernel parameters based on type
      {
        kernelParams = mkMerge [
          (mkIf (cfg.type == "qemu" || cfg.type == "auto") [
            "elevator=noop" # Better for VirtIO
            "transparent_hugepage=madvise"
          ])

          (mkIf (cfg.type == "virtualbox") [
            "vga=0x318" # VirtualBox graphics mode
          ])

          (mkIf (cfg.type == "vmware") [
            "vmwgfx.enable_fbdev=1" # VMware graphics
          ])
        ];
      }
    ];

    # Hardware configuration for VMs
    hardware = mkMerge [
      {
        # Graphics configuration
        graphics = mkIf cfg.optimizations.graphics {
          enable = true;
          enable32Bit = true;

          extraPackages = with pkgs; [
            mesa
            libGL
          ] ++ optionals (cfg.type == "qemu" || cfg.type == "auto") [
            virglrenderer
            qemu
          ] ++ optionals (cfg.type == "virtualbox") [
            virtualboxGuestAdditions
          ] ++ optionals (cfg.type == "vmware") [
            xorg.xf86videovmware
          ];
        };

        # Audio disabled in VMs by default (use services.pulseaudio if needed)
        # pulseaudio.enable = mkDefault false;
      }
    ];

    # Networking optimizations for VMs
    networking = mkIf cfg.optimizations.networking {
      # Use NetworkManager for flexibility
      networkmanager.enable = mkDefault true;

      # Common VM interface configurations with fallbacks
      interfaces = {
        # QEMU/KVM interfaces
        enp0s3.useDHCP = mkDefault true;
        enp1s0.useDHCP = mkDefault true;
        ens3.useDHCP = mkDefault true;

        # Legacy naming / Hyper-V
        eth0.useDHCP = mkDefault true;
        eth1.useDHCP = mkDefault true;

        # VirtualBox
        enp0s8.useDHCP = mkDefault true;

        # VMware
        ens32.useDHCP = mkDefault true;
        ens33.useDHCP = mkDefault true;
      };

      # Disable IPv6 by default in VMs for simplicity
      enableIPv6 = lib.mkForce false;
    };

    # System services for VMs
    services = mkMerge [
      {
        # Enable guest services based on VM type
        qemuGuest.enable = mkIf (cfg.type == "qemu" || cfg.type == "auto") true;

        # Time synchronization
        timesyncd.enable = mkIf cfg.guestTools.timeSync (mkDefault true);
        ntp.enable = mkIf (!cfg.guestTools.timeSync && cfg.type != "qemu") (mkDefault true);

        # VM-specific clipboard and integration services
        spice-vdagentd.enable = mkIf
          (
            cfg.guestTools.clipboard &&
            (cfg.type == "qemu" || cfg.type == "auto")
          )
          true;

        # SSH for remote access
        openssh = mkIf (cfg.type != "desktop") {
          enable = mkDefault true;
          settings = {
            PasswordAuthentication = mkDefault true;
            PermitRootLogin = mkDefault "no";
            X11Forwarding = mkForce true; # VMs often need X11 forwarding
          };
        };
      }

      # Hardware-specific services (disabled for VMs)
      {
        # Power management not needed in VMs
        thermald.enable = mkForce false;
        tlp.enable = mkForce false;

        # No need for firmware updates in VMs
        fwupd.enable = mkForce false;

        # Disable hardware monitoring
        smartd.enable = mkDefault false;

        # VM-optimized journal settings
        journald.extraConfig = ''
          SystemMaxUse=100M
          RuntimeMaxUse=50M
          ForwardToSyslog=no
        '';
      }

      # Audio services (corrected from hardware.pulseaudio deprecation)
      (mkIf (cfg.type != "headless") {
        pulseaudio = {
          enable = mkDefault false; # Disabled by default, enable if needed
        };
      })
    ];

    # System packages for VM environments
    environment.systemPackages = with pkgs; [
      # Basic VM tools
      qemu-utils

      # Network diagnostics
      inetutils
      netcat

      # System monitoring
      htop
      iotop
      lsof

      # File operations
      rsync
      unzip

      # Text editors
      vim
      nano
    ] ++ optionals (cfg.type == "qemu" || cfg.type == "auto") [
      # QEMU-specific tools
      spice-gtk
      virtiofsd
    ] ++ optionals (cfg.type == "virtualbox") [
      # VirtualBox guest additions
      virtualboxGuestAdditions
    ] ++ optionals (cfg.type == "vmware") [
      # VMware tools would go here
      open-vm-tools
    ];

    # Performance optimizations for VMs
    systemd = mkMerge [
      (mkIf cfg.optimizations.performance {
        # Faster service timeouts
        settings.Manager = {
          DefaultTimeoutStartSec = "30s";
          DefaultTimeoutStopSec = "15s";
        };
      })

      # VM-specific systemd configuration
      {
        tmpfiles.rules = [
          # Create VM-specific directories
          "d /var/lib/vm-tools 0755 root root -"
          "d /tmp/vm-shared 1777 root root -"
        ];
      }
    ];

    # Console configuration for VMs
    console = mkMerge [
      {
        earlySetup = true;
        keyMap = mkDefault "us";
      }

      (mkIf cfg.serial.enable {
        # Enable serial console (use mkForce to handle conflict with core locale)
        useXkbConfig = mkForce false;
      })
    ];

    # Security adjustments for VM environments
    security = {
      # VMs often need less strict security for development
      sudo.wheelNeedsPassword = mkDefault false;

      # Disable some security features that interfere with VMs
      lockKernelModules = mkDefault false;
      protectKernelImage = mkDefault false;
    };

    # User configuration for VMs
    users = {
      # Allow users to manage VMs
      users.root.openssh.authorizedKeys.keys = mkDefault [ ];

      # Create default groups for VM management
      groups = {
        vboxusers = mkIf (cfg.type == "virtualbox") { };
        docker = mkIf cfg.guestTools.folderSharing { };
      };
    };

    # Filesystem optimizations for VMs
    fileSystems = mkIf cfg.optimizations.storage {
      "/" = {
        options = [ "noatime" "nodiratime" ];
      };
    };

    # Power management (disabled for VMs)
    powerManagement = {
      enable = mkDefault false;
      cpuFreqGovernor = mkDefault null;
    };


    # Environment variables for VM detection
    environment.sessionVariables = {
      # Help applications detect VM environment
      NIXOS_IN_VM = "1";
      XDG_CURRENT_DESKTOP = mkIf (cfg.type == "qemu") "GNOME"; # Help with app compatibility
    };


  };
}
