{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.virtualization.podman;
in
{
  options.modules.virtualization.podman = {
    enable = mkEnableOption "Podman containerization with rootless support";

    dockerCompat = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Docker compatibility layer";
    };

    rootless = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable rootless podman for regular users";
      };

      setSocketVariable = mkOption {
        type = types.bool;
        default = true;
        description = "Set DOCKER_HOST socket variable for rootless podman";
      };
    };

    networking = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable container networking";
      };

      defaultNetwork = mkOption {
        type = types.str;
        default = "podman";
        description = "Default network name for containers";
      };

      dns = mkOption {
        type = types.listOf types.str;
        default = [ "1.1.1.1" "8.8.8.8" ];
        description = "DNS servers for containers";
      };
    };

    storage = {
      driver = mkOption {
        type = types.str;
        default = "overlay";
        description = "Storage driver for containers";
      };

      runRoot = mkOption {
        type = types.str;
        default = "/run/containers/storage";
        description = "Directory for container runtime files";
      };

      graphRoot = mkOption {
        type = types.str;
        default = "/var/lib/containers/storage";
        description = "Directory for container storage";
      };
    };

    registries = {
      search = mkOption {
        type = types.listOf types.str;
        default = [
          "registry.fedoraproject.org"
          "registry.access.redhat.com"
          "docker.io"
          "quay.io"
        ];
        description = "Container registries to search for images";
      };

      insecure = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Insecure registries (HTTP instead of HTTPS)";
      };

      block = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Blocked registries";
      };
    };

    additionalTools = {
      buildah = mkOption {
        type = types.bool;
        default = true;
        description = "Install Buildah for building container images";
      };

      skopeo = mkOption {
        type = types.bool;
        default = true;
        description = "Install Skopeo for working with container images and repositories";
      };

      podman-compose = mkOption {
        type = types.bool;
        default = true;
        description = "Install podman-compose for Docker Compose compatibility";
      };

      podman-tui = mkOption {
        type = types.bool;
        default = true;
        description = "Install Podman TUI for terminal user interface";
      };

      dive = mkOption {
        type = types.bool;
        default = false;
        description = "Install dive for exploring container images";
      };

      ctop = mkOption {
        type = types.bool;
        default = false;
        description = "Install ctop for container monitoring";
      };
    };

    autoUpdate = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic container updates";
      };

      onCalendar = mkOption {
        type = types.str;
        default = "daily";
        description = "Systemd calendar expression for auto-updates";
      };
    };

    quadlet = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Quadlet for systemd integration";
      };
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Additional packages for container development";
      example = literalExpression ''
        with pkgs; [
          distrobox
          toolbox
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    # Enable NixOS built-in Podman module (use mkDefault to allow overrides)
    virtualisation.podman = {
      enable = mkDefault true;

      # Docker compatibility
      dockerCompat = mkDefault cfg.dockerCompat;
      dockerSocket.enable = mkDefault cfg.dockerCompat;

      # Default network settings
      defaultNetwork.settings = mkIf cfg.networking.enable {
        dns_enabled = true;
        driver = "bridge";
        name = cfg.networking.defaultNetwork;
      };

      # Rootless configuration
      autoPrune = {
        enable = mkDefault true;
        dates = mkDefault "weekly";
        flags = mkDefault [ "--all" ];
      };
    };

    # Enable NixOS built-in containers module (use mkDefault to allow overrides)
    virtualisation.containers = {
      enable = mkDefault true;

      # Rootless configuration
      # Note: Users must be manually added to extraGroups in host configuration
      # to enable rootless access: extraGroups = [ "podman" ];

      # Container storage configuration
      storage.settings = {
        storage = {
          driver = cfg.storage.driver;
          runroot = cfg.storage.runRoot;
          graphroot = cfg.storage.graphRoot;

          options = {
            overlay = {
              mountopt = "nodev,metacopy=on";
            };
          };
        };
      };

      # Registry configuration
      registries = {
        search = cfg.registries.search;
        insecure = cfg.registries.insecure;
        block = cfg.registries.block;
      };

      # Policy configuration for image verification
      policy = {
        default = [{ type = "insecureAcceptAnything"; }];
        transports = {
          docker-daemon = {
            "" = [{ type = "insecureAcceptAnything"; }];
          };
        };
      };
    };

    # System packages for containers
    environment.systemPackages = with pkgs; [
      podman

      # Additional container tools
      (mkIf cfg.additionalTools.buildah buildah)
      (mkIf cfg.additionalTools.skopeo skopeo)
      (mkIf cfg.additionalTools.podman-compose podman-compose)
      (mkIf cfg.additionalTools.podman-tui podman-tui)
      (mkIf cfg.additionalTools.dive dive)
      (mkIf cfg.additionalTools.ctop ctop)

      # Container development tools
      conmon
      crun
      fuse-overlayfs
      slirp4netns

      # Extra packages specified by user
    ] ++ cfg.extraPackages;

    # User groups for container access
    users.groups.podman = { };

    # Note: Users need to be manually added to 'podman' group for rootless access
    # This avoids circular dependencies in the module system
    # Add users to the podman group manually in host configuration:

    # Systemd services
    systemd.services = {
      # Podman auto-update service
      podman-auto-update = mkIf cfg.autoUpdate.enable {
        description = "Podman auto-update service";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.podman}/bin/podman auto-update";
          ExecStartPost = "${pkgs.podman}/bin/podman image prune -f";
        };
      };
    };

    # Systemd timers
    systemd.timers = {
      podman-auto-update = mkIf cfg.autoUpdate.enable {
        description = "Podman auto-update timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.autoUpdate.onCalendar;
          Persistent = true;
        };
      };
    };

    # Quadlet support (systemd integration for containers)
    systemd.packages = mkIf cfg.quadlet.enable [ pkgs.podman ];

    # Environment variables for container tools
    environment.sessionVariables = mkMerge [
      {
        # Podman configuration
        CONTAINERS_CONF = "/etc/containers/containers.conf";
        CONTAINERS_STORAGE_CONF = "/etc/containers/storage.conf";
        CONTAINERS_REGISTRIES_CONF = "/etc/containers/registries.conf";
        CONTAINERS_POLICY_JSON = "/etc/containers/policy.json";

        # Buildah configuration
        BUILDAH_FORMAT = "docker";
        BUILDAH_ISOLATION = "chroot";

        # Default container runtime
        CONTAINER_RUNTIME = "podman";
      }

      # Docker socket compatibility for rootless
      (mkIf (cfg.rootless.enable && cfg.rootless.setSocketVariable) {
        DOCKER_HOST = "unix:///run/user/$UID/podman/podman.sock";
      })
    ];

    # Let the built-in NixOS podman module handle container configuration files
    # Our module focuses on high-level configuration options instead of duplicating
    # the complex configuration file management

    # Kernel modules needed for containers
    boot.kernelModules = [ "overlay" "br_netfilter" ];

    # Sysctl settings for containers
    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-iptables" = mkDefault 1;
      "net.bridge.bridge-nf-call-ip6tables" = mkDefault 1;
      "net.ipv4.ip_forward" = mkDefault 1;
      "user.max_user_namespaces" = mkDefault 28633;
    };

    # Enable cgroups v2 for better resource management
    # Note: systemd.enableUnifiedCgroupHierarchy is deprecated - cgroups v2 is now default

    # Ensure required directories exist
    systemd.tmpfiles.rules = [
      "d /var/lib/containers 0755 root root -"
      "d /var/lib/containers/storage 0755 root root -"
      "d /run/containers 0755 root root -"
      "d /run/containers/storage 0755 root root -"
    ];

    # Security configuration
    security.unprivilegedUsernsClone = cfg.rootless.enable;

    # Firewall rules for container networking
    networking.firewall = mkIf cfg.networking.enable {
      # Allow container-to-container communication
      trustedInterfaces = [ "podman+" "cni+" ];
    };

    # Additional networking configuration
    networking.networkmanager = mkIf config.networking.networkmanager.enable {
      unmanaged = [ "interface-name:veth*" "interface-name:podman*" "interface-name:cni*" ];
    };
  };
}
