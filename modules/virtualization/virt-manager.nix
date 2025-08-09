{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.virtualization.virt-manager;
in
{
  options.modules.virtualization.virt-manager = {
    enable = mkEnableOption "Virtual machine manager applications for different desktop environments";

    applications = {
      virt-manager = mkOption {
        type = types.bool;
        default = true;
        description = "Install virt-manager (GTK-based, works with GNOME/GTK DEs)";
      };

      gnome-boxes = mkOption {
        type = types.bool;
        default = false;
        description = "Install GNOME Boxes (GNOME-native virtualization)";
      };

      virt-viewer = mkOption {
        type = types.bool;
        default = true;
        description = "Install virt-viewer for viewing VM consoles";
      };

      qemu-gui = mkOption {
        type = types.bool;
        default = false;
        description = "Install QEMU GUI tools";
      };

      cockpit-machines = mkOption {
        type = types.bool;
        default = false;
        description = "Install Cockpit machines plugin for web-based management";
      };
    };

    remoteConnections = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable remote libvirt connections";
      };

      ssh = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH-based remote connections";
      };
    };

    integrations = {
      nautilus = mkOption {
        type = types.bool;
        default = false;
        description = "Install Nautilus integration for GNOME Files";
      };

      dolphin = mkOption {
        type = types.bool;
        default = false;
        description = "Install Dolphin integration for KDE";
      };
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional virtualization-related packages";
      example = literalExpression ''
        with pkgs; [
          vagrant
          vagrant-libvirt
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    # Ensure libvirt is enabled
    assertions = [
      {
        assertion = config.modules.virtualization.libvirt.enable or false;
        message = "virt-manager requires libvirt to be enabled. Enable modules.virtualization.libvirt";
      }
    ];

    # System packages for virtual machine management
    environment.systemPackages = with pkgs; [
      # Core VM management applications
      (mkIf cfg.applications.virt-manager virt-manager)
      (mkIf cfg.applications.gnome-boxes gnome-boxes)
      (mkIf cfg.applications.virt-viewer virt-viewer)
      (mkIf cfg.applications.qemu-gui qemu_full)

      # Remote access tools
      (mkIf cfg.remoteConnections.ssh openssh)

      # Additional tools for VM management
      libosinfo # OS information database
      osinfo-db-tools # OS database tools
      libguestfs # Guest filesystem access
      guestfs-tools # Guest tools

      # Integration packages
      (mkIf cfg.integrations.nautilus gvfs)

      # Cockpit machines plugin
      (mkIf cfg.applications.cockpit-machines cockpit-machines)

      # User-specified extra packages
    ] ++ cfg.extraPackages;

    # GNOME Boxes specific configuration
    programs.gnome-boxes = mkIf cfg.applications.gnome-boxes {
      enable = true;
    };

    # Cockpit for web-based management
    services.cockpit = mkIf cfg.applications.cockpit-machines {
      enable = true;
      openFirewall = true;
      settings = {
        WebService = {
          AllowUnencrypted = "true";
        };
      };
    };


    # Desktop entries and MIME types
    xdg = {
      mime = {
        enable = true;
        defaultApplications = {
          # VM disk images
          "application/x-qemu-disk" = mkIf cfg.applications.virt-manager [ "virt-manager.desktop" ];
          "application/x-virtualbox-vdi" = mkIf cfg.applications.virt-manager [ "virt-manager.desktop" ];
          "application/x-vmware-disk" = mkIf cfg.applications.virt-manager [ "virt-manager.desktop" ];

          # VM configuration files
          "application/x-libvirt-xml" = mkIf cfg.applications.virt-manager [ "virt-manager.desktop" ];
          "text/x-libvirt-xml" = mkIf cfg.applications.virt-manager [ "virt-manager.desktop" ];
        };
      };
    };

    # Polkit rules for VM management applications
    security.polkit.extraConfig = ''
      // Allow users in libvirtd group to manage VMs through GUI applications
      polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.libvirt") == 0 &&
              subject.isInGroup("libvirtd")) {
              return polkit.Result.YES;
          }
      });

      // GNOME Boxes permissions
      ${optionalString cfg.applications.gnome-boxes ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.libvirt.unix.manage" ||
               action.id == "org.libvirt.api.domain.start" ||
               action.id == "org.libvirt.api.domain.save" ||
               action.id == "org.libvirt.api.domain.suspend" ||
               action.id == "org.libvirt.api.domain.resume") &&
              subject.user == "gnome-initial-setup") {
              return polkit.Result.YES;
          }
      });
      ''}

      // Cockpit machines permissions
      ${optionalString cfg.applications.cockpit-machines ''
      polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.libvirt") == 0 &&
              subject.user == "cockpit-ws") {
              return polkit.Result.YES;
          }
      });
      ''}
    '';

    # D-Bus configuration for VM management
    services.dbus.packages = with pkgs; [
      (mkIf cfg.applications.virt-manager virt-manager)
      (mkIf cfg.applications.gnome-boxes gnome-boxes)
    ];

    # NetworkManager integration for bridge connections
    networking.networkmanager = mkIf config.networking.networkmanager.enable {
      plugins = with pkgs; [
        networkmanager-l2tp
        networkmanager-vpnc
        networkmanager-openconnect
      ];

      # Don't manage libvirt bridges
      unmanaged = [ "interface-name:virbr*" "interface-name:br*" ];
    };

    # Firewall configuration for remote management
    networking.firewall = mkMerge [
      (mkIf cfg.remoteConnections.enable {
        allowedTCPPorts = [ 16509 ]; # libvirtd TLS port
      })

      (mkIf (cfg.remoteConnections.enable && !cfg.remoteConnections.ssh) {
        allowedTCPPorts = [ 16514 ]; # libvirtd TCP port (insecure)
      })

      (mkIf cfg.applications.cockpit-machines {
        allowedTCPPorts = [ 9090 ]; # Cockpit web interface
      })
    ];

    # Desktop environment specific configurations
    services.xserver = mkIf config.services.xserver.enable {
      # SPICE client integration
      displayManager.sessionPackages = with pkgs; [
        (mkIf cfg.applications.virt-viewer spice-gtk)
      ];
    };

    # GNOME specific integrations
    programs.dconf.enable = mkIf cfg.applications.gnome-boxes true;

    services.gnome = mkIf (cfg.applications.gnome-boxes && config.services.xserver.desktopManager.gnome.enable) {
      gnome-initial-setup.enable = mkDefault true;
    };

    # KDE specific integrations
    programs.kde = mkIf (cfg.integrations.dolphin && config.services.xserver.desktopManager.plasma5.enable) {
      kdeconnect.enable = mkDefault true;
    };

    # Font packages for better VM display
    fonts.packages = with pkgs; [
      liberation_ttf # Better font rendering in VMs
      dejavu_fonts # Wide character support
      noto-fonts # Unicode support
      noto-fonts-cjk # Asian language support
      noto-fonts-emoji # Emoji support
    ];

    # Environment variables for VM management
    environment.sessionVariables = {
      # SPICE client configuration
      SPICE_DEBUG_LEVEL = mkIf cfg.applications.virt-viewer "1";

      # virt-manager configuration
      VIRT_MANAGER_DEBUG = mkIf cfg.applications.virt-manager "0";

      # Libvirt default URI
      LIBVIRT_DEFAULT_URI = "qemu:///system";

      # GNOME Boxes configuration
      BOXES_DEBUG = mkIf cfg.applications.gnome-boxes "0";
    };

    # System-wide configuration files
    environment.etc = {
      # libvirt client configuration
      "libvirt/libvirt.conf" = mkIf cfg.remoteConnections.enable {
        text = ''
          # Default libvirt URI
          uri_default = "qemu:///system"

          ${optionalString cfg.remoteConnections.ssh ''
          # Enable SSH transport
          remote_display_port_min = 5900
          remote_display_port_max = 65535
          ''}

          ${optionalString (!cfg.remoteConnections.ssh) ''
          # Enable TCP transport (less secure)
          listen_tls = 0
          listen_tcp = 1
          auth_tcp = "none"
          ''}
        '';
      };

      # virt-manager configuration template
      "virt-manager/virt-manager.conf" = mkIf cfg.applications.virt-manager {
        text = ''
          [ui]
          # Show system tray icon
          icon-name = virt-manager

          # Console settings
          console-accels = false
          console-scaling = 1

          [stats]
          # Update interval in seconds
          update-interval = 1

          # History length
          history-length = 120

          [console]
          # Console resize settings
          resize-guest = 1

          [urls]
          # Help URLs
          local-libvirt = qemu:///system
        '';
      };

      # GNOME Boxes configuration
      "gnome-boxes/boxes.conf" = mkIf cfg.applications.gnome-boxes {
        text = ''
          [general]
          # Default machine settings
          cpu-cores = 2
          memory = 2048
          disk-size = 20

          # UI preferences
          show-suggested = true
          first-run = false

          [remote]
          # Remote connection settings
          save-password = false
        '';
      };
    };

    # User directories for VM storage
    systemd.tmpfiles.rules = [
      # Create user VM directories
      "d /home/%i/VirtualMachines 0755 %i users -"
      "d /home/%i/.config/libvirt 0755 %i users -"

      # GNOME Boxes storage
      "d /home/%i/.local/share/gnome-boxes 0755 %i users -"
      "d /home/%i/.local/share/gnome-boxes/images 0755 %i users -"

      # Cockpit directories
      "d /var/lib/cockpit 0755 root root -"
      "d /etc/cockpit 0755 root root -"
    ];

    # Additional services for VM management
    systemd.services = {
      # Update osinfo database
      osinfo-db-update = {
        description = "Update OS info database";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "root";
          Group = "root";
          ExecStart = "${pkgs.osinfo-db-tools}/bin/osinfo-db-import --local";
        };
        # Run weekly
        startAt = "weekly";
      };
    };

    # Enable required services
    services = {
      # SPICE guest agent service (for guests)
      spice-vdagentd.enable = mkIf cfg.applications.virt-viewer true;

      # Enable automatic login for single-user systems with VMs
      getty.autologinUser = mkIf cfg.applications.gnome-boxes null;
    };
  };
}
