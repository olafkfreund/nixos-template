{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.virtualization.libvirt;
in
{
  options.modules.virtualization.libvirt = {
    enable = mkEnableOption "Libvirt virtualization with QEMU/KVM";

    qemu = {
      package = mkOption {
        type = types.package;
        default = pkgs.qemu_kvm;
        description = "QEMU package to use";
      };

      ovmf = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable OVMF UEFI firmware for virtual machines";
        };
      };

      swtpm = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable software TPM for virtual machines";
        };
      };
    };

    networking = {
      defaultNetwork = mkOption {
        type = types.bool;
        default = true;
        description = "Enable default NAT network";
      };

      bridgeInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Network interface to bridge (e.g., 'enp0s31f6')";
        example = "enp0s31f6";
      };
    };

    storage = {
      pools = mkOption {
        type = types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Storage pool name";
            };
            type = mkOption {
              type = types.str;
              default = "dir";
              description = "Storage pool type";
            };
            path = mkOption {
              type = types.str;
              description = "Storage pool path";
            };
          };
        });
        default = [
          {
            name = "default";
            type = "dir";
            path = "/var/lib/libvirt/images";
          }
        ];
        description = "Storage pools to create";
      };
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Users to add to libvirtd group";
    };

    spiceUSBRedirection = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SPICE USB redirection";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra libvirtd configuration";
    };
  };

  config = mkIf cfg.enable {
    # Enable virtualization
    virtualisation = {
      libvirtd = {
        enable = true;
        package = pkgs.libvirt;

        # QEMU configuration
        qemu = {
          package = cfg.qemu.package;
          runAsRoot = false;
          swtpm.enable = cfg.qemu.swtpm.enable;
          ovmf = mkIf cfg.qemu.ovmf.enable {
            enable = true;
            packages = with pkgs; [
              OVMFFull.fd
              pkgsCross.aarch64-multiplatform.OVMF.fd
            ];
          };
        };

        # Extra configuration
        extraConfig = ''
          # Enable nested virtualization
          unix_sock_group = "libvirtd"
          unix_sock_ro_perms = "0777"
          unix_sock_rw_perms = "0770"
          auth_unix_ro = "none"
          auth_unix_rw = "none"
          
          # Logging
          log_level = 3
          log_filters = "3:remote 4:event"
          log_outputs = "3:syslog:libvirtd"
          
          # Process limits
          max_clients = 5000
          max_workers = 20
          max_requests = 20
          max_client_requests = 5
          
          ${cfg.extraConfig}
        '';

        # Daemon configuration
        onBoot = "start";
        onShutdown = "shutdown";
      };

      # Enable KVM
      kvmgt.enable = mkDefault true;

      # Enable SPICE guest tools
      spiceUSBRedirection.enable = cfg.spiceUSBRedirection;
    };

    # System packages for virtualization
    environment.systemPackages = with pkgs; [
      # Core virtualization tools
      libvirt
      qemu_kvm

      # Guest tools and drivers
      virtio-win
      spice-gtk
      spice-protocol
      win-virtio

      # USB redirection
      (mkIf cfg.spiceUSBRedirection spice-gtk)
      (mkIf cfg.spiceUSBRedirection usbredir)

      # Network tools
      bridge-utils
      iptables

      # Additional utilities
      libguestfs
      guestfs-tools

      # UEFI firmware (if enabled)
      (mkIf cfg.qemu.ovmf.enable OVMF)
      (mkIf cfg.qemu.ovmf.enable edk2)

      # TPM emulation (if enabled)
      (mkIf cfg.qemu.swtpm.enable swtpm)
    ];

    # User groups
    users.groups.libvirtd = { };

    # Add specified users to libvirtd group
    users.users = listToAttrs (map
      (user: {
        name = user;
        value = {
          extraGroups = [ "libvirtd" "kvm" ];
        };
      })
      cfg.users);

    # Enable required kernel modules
    boot.kernelModules = [
      "kvm-intel" # Intel KVM
      "kvm-amd" # AMD KVM
      "vfio" # VFIO for device passthrough
      "vfio_iommu_type1"
      "vfio_pci"
      "vhost-net" # Networking performance
      "tun" # TUN/TAP networking
      "bridge" # Network bridging
      "macvtap" # MacVTap networking
    ];

    # Kernel parameters for virtualization
    boot.kernelParams = [
      # Enable IOMMU for device passthrough
      "intel_iommu=on"
      "amd_iommu=on"

      # Nested virtualization
      "kvm-intel.nested=1"
      "kvm-amd.nested=1"

      # Huge pages for better performance
      "hugepagesz=2M"
      "hugepages=1024"
    ];

    # Systemd services
    systemd.services = {
      # Custom libvirt network setup
      libvirt-networks = mkIf cfg.networking.defaultNetwork {
        description = "Setup libvirt networks";
        after = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Wait for libvirtd to be ready
          sleep 5
          
          # Define and start default network if it doesn't exist
          if ! ${pkgs.libvirt}/bin/virsh net-list --all | grep -q "default"; then
            ${pkgs.libvirt}/bin/virsh net-define ${pkgs.writeText "default-network.xml" ''
              <network>
                <name>default</name>
                <uuid>9a05da11-e96b-47f3-8253-a3a482e445f5</uuid>
                <forward mode='nat'>
                  <nat>
                    <port start='1024' end='65535'/>
                  </nat>
                </forward>
                <bridge name='virbr0' stp='on' delay='0'/>
                <ip address='192.168.122.1' netmask='255.255.255.0'>
                  <dhcp>
                    <range start='192.168.122.2' end='192.168.122.254'/>
                  </dhcp>
                </ip>
              </network>
            ''}
          fi
          
          # Auto-start default network
          ${pkgs.libvirt}/bin/virsh net-autostart default 2>/dev/null || true
          ${pkgs.libvirt}/bin/virsh net-start default 2>/dev/null || true
        '';
      };

      # Storage pool setup
      libvirt-storage-pools = {
        description = "Setup libvirt storage pools";
        after = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Wait for libvirtd to be ready
          sleep 5
          
          ${concatMapStringsSep "\n" (pool: ''
            # Create directory if it doesn't exist
            mkdir -p ${pool.path}
            
            # Define storage pool if it doesn't exist
            if ! ${pkgs.libvirt}/bin/virsh pool-list --all | grep -q "${pool.name}"; then
              ${pkgs.libvirt}/bin/virsh pool-define-as ${pool.name} ${pool.type} - - - - ${pool.path}
            fi
            
            # Build and start storage pool
            ${pkgs.libvirt}/bin/virsh pool-build ${pool.name} 2>/dev/null || true
            ${pkgs.libvirt}/bin/virsh pool-autostart ${pool.name} 2>/dev/null || true
            ${pkgs.libvirt}/bin/virsh pool-start ${pool.name} 2>/dev/null || true
          '') cfg.storage.pools}
        '';
      };
    };

    # Network configuration
    networking = {
      # Enable bridge networking if specified
      bridges = mkIf (cfg.networking.bridgeInterface != null) {
        br0 = {
          interfaces = [ cfg.networking.bridgeInterface ];
        };
      };

      # Firewall rules for virtualization
      firewall = {
        # Allow libvirt bridge traffic
        trustedInterfaces = [ "virbr0" "br0" ];

        # Allow SPICE and VNC ports
        allowedTCPPorts = [ 5900 5901 5902 5903 5904 5905 ];
        allowedTCPPortRanges = [
          { from = 5900; to = 5999; } # VNC
          { from = 61000; to = 61999; } # SPICE
        ];
      };
    };

    # Sysctl parameters for virtualization
    boot.kernel.sysctl = {
      # Network performance
      "net.bridge.bridge-nf-call-iptables" = 0;
      "net.bridge.bridge-nf-call-arptables" = 0;
      "net.bridge.bridge-nf-call-ip6tables" = 0;

      # Virtual memory
      "vm.swappiness" = 10;
      "vm.dirty_ratio" = 15;
      "vm.dirty_background_ratio" = 5;

      # Huge pages
      "vm.nr_hugepages" = 1024;
    };

    # Enable hugepages
    systemd.tmpfiles.rules = [
      "d /dev/hugepages 0755 root root -"
      "d /var/lib/libvirt 0755 root root -"
      "d /var/lib/libvirt/images 0755 root root -"
    ];

    # Polkit rules for libvirt
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id == "org.libvirt.unix.manage" &&
              subject.isInGroup("libvirtd")) {
                  return polkit.Result.YES;
          }
      });
      
      polkit.addRule(function(action, subject) {
          if (action.id == "org.libvirt.api.domain.start" &&
              subject.isInGroup("libvirtd")) {
                  return polkit.Result.YES;
          }
      });
    '';

    # Udev rules for USB passthrough
    services.udev.extraRules = ''
      # Allow libvirt to access USB devices
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", GROUP="libvirtd", MODE="0664"
      
      # KVM device permissions
      KERNEL=="kvm", GROUP="kvm", MODE="0666"
      
      # VFIO device permissions for GPU passthrough
      SUBSYSTEM=="vfio", GROUP="libvirtd", MODE="0666"
    '';

    # Apparmor profiles (if enabled)
    security.apparmor = mkIf config.security.apparmor.enable {
      packages = [ pkgs.libvirt ];
    };

    # Environment variables
    environment.sessionVariables = {
      LIBVIRT_DEFAULT_URI = "qemu:///system";
    };
  };
}
