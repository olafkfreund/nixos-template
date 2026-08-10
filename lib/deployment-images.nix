# Deployment Images Factory
# Generates deployment images for various cloud providers and platforms
{
  inputs,
  outputs,
  nixpkgs,
}:

let
  inherit (nixpkgs) lib;

  # nixos-generators format names -> the equivalent in nixpkgs' own
  # `system.build.images`, which replaced it upstream in NixOS 25.05.
  formatModule = {
    amazon = "amazon";
    azure = "azure";
    do = "digital-ocean";
    iso = "iso";
    lxc = "lxc";
    qcow = "qemu";
    virtualbox = "virtualbox";
    vmware = "vmware";
  };

  # Build one image: evaluate the host, then take the format's output from
  # `system.build.images`. This is what nixos-generators did, minus the
  # dependency.
  #
  # The per-image settings go into `image.modules.<format>` rather than the base
  # module list. `system.build.images.<format>` is a separate evaluation built
  # with extendModules, so options a format declares -- `isoImage.*`, for
  # instance -- only exist there. `image.modules` is a deferredModule, so this
  # merges with the format module nixpkgs already puts there.
  mkImage =
    baseConfig: config:
    let
      fmt = formatModule.${config.format} or (throw "unknown image format: ${config.format}");
      evaluated = nixpkgs.lib.nixosSystem (
        baseConfig
        // {
          modules = baseConfig.modules ++ [ { image.modules.${fmt} = config.extraConfig; } ];
        }
      );
    in
    evaluated.config.system.build.images.${fmt};

  # Factory function to create deployment images
  mkDeploymentImages =
    {
      system ? "x86_64-linux",
    }:
    let
      pkgs = nixpkgs.legacyPackages.${system};

      # Base configuration shared by all deployment images
      baseConfig = {
        inherit system;
        specialArgs = {
          inherit inputs outputs;
          flakeMeta = null;
        };
        modules = [
          ../hosts/common.nix
          ({ lib, pkgs, ... }: {
            # Allow unfree packages for deployment images
            nixpkgs.config.allowUnfree = true;
            # Optimize for deployment images
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Enable core features by default
            modules = {
              core.nixOptimization.enable = true;
              hardware.detection.enable = true;
              services.monitoring.enable = false; # Enable per-deployment as needed
            };

            # Default user for images
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [
                "wheel"
                "networkmanager"
              ];
              initialPassword = "nixos";
            };

            # Security: Lock root account consistently
            users.users.root = {
              hashedPassword = lib.mkOverride 100 "!"; # Lock root account
              password = lib.mkOverride 100 null;
              initialPassword = lib.mkOverride 100 null;
              initialHashedPassword = lib.mkOverride 100 null;
              hashedPasswordFile = lib.mkOverride 100 null;
            };

            # Enable SSH by default
            services.openssh = {
              enable = true;
              settings.PermitRootLogin = lib.mkDefault "no";
              settings.PasswordAuthentication = true; # For initial setup
            };

            # Essential packages for deployment
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
              htop
              tree
            ];

            # Base disk space optimizations for all images
            nix = {
              gc.automatic = lib.mkDefault true;
              optimise.automatic = lib.mkDefault true;
            };

            # Reduce documentation in deployment images
            documentation.enable = lib.mkForce false;
          })
        ];
      };

      # Platform-specific configurations
      platformConfigs = {
        # Cloud deployment images
        aws = {
          format = "amazon";
          extraConfig = {
            # AWS-specific optimizations
            ec2.hvm = true;
            boot.loader.grub.device = "/dev/xvda";
            fileSystems."/" = {
              device = "/dev/xvda1";
              fsType = "ext4";
            };
          };
        };

        azure = {
          format = "azure";
          extraConfig = {
            # Azure-specific configurations
            environment.systemPackages = with pkgs; [ waagent ];
          };
        };

        digitalocean = {
          format = "do";
          extraConfig = {
            # Digital Ocean specific configurations
            services.openssh.enable = true;
          };
        };

        # Virtualization images
        vmware = {
          format = "vmware";
          extraConfig = {
            # VMware-specific optimizations
            virtualisation.vmware.guest.enable = true;
            services.xserver.videoDrivers = [ "vmware" ];
          };
        };

        qemu = {
          format = "qcow";
          extraConfig = {
            # QEMU/KVM optimizations
            services.qemuGuest.enable = true;
            services.spice-vdagentd.enable = true;
          };
        };

        # Container images
        lxc = {
          format = "lxc";
          extraConfig = {
            # LXC container optimizations. modules/core/boot.nix turns on
            # systemd-boot for every host; a container has no bootloader, and
            # leaving both it and the container's init script enabled defines
            # system.build.installBootLoader twice.
            boot.loader.systemd-boot.enable = lib.mkForce false;
            boot.isContainer = true;
            services.openssh.enable = true;
            security.audit.enable = lib.mkForce false;
          };
        };

        # Installation media
        iso = {
          format = "iso";
          extraConfig = {
            # Live ISO optimizations
            isoImage = {
              makeEfiBootable = true;
              makeUsbBootable = true;
              squashfsCompression = "gzip -Xcompression-level 1";
            };

            # Include useful tools on live system
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
              htop
              tree
              gparted
              firefox
              networkmanager-openvpn
              wpa_supplicant_gui
            ];
          };
        };
      };

      # Specialized image configurations
      specializedImages = {
        # VirtualBox with desktop environment
        virtualbox-desktop = {
          format = "virtualbox";
          extraConfig = {
            # VirtualBox-specific optimizations.
            # The `virtualbox` video driver is deprecated upstream for kernel 7.0+,
            # so we rely on the nixpkgs default (modesetting/fbdev) instead.
            virtualisation.virtualbox.guest.enable = true;
            services.xserver.enable = true;

            # Use updated option names for NixOS 24.05+
            services.desktopManager.gnome.enable = true;
            services.displayManager.gdm.enable = true;

            # Essential system packages
            environment.systemPackages = with pkgs; [
              vim
              git
              curl
              wget
              htop
              firefox
            ];

            # Network configuration
            networking.networkmanager.enable = true;
            networking.firewall.enable = lib.mkForce false; # Disabled for VM ease of use

            # Keep VM image size reasonable
            nix.gc.automatic = true;
            nix.optimise.automatic = true;
            system.stateVersion = "26.05";
          };
        };

        # Development environment - optimized for disk space
        development-vm = {
          format = "qcow";
          extraConfig = {
            # Essential development tools only
            environment.systemPackages = with pkgs; [
              git
              vim
              neovim
              nodejs
              python3
              # Remove heavy packages to reduce disk usage
              # rustc cargo - can be installed on demand
              # docker docker-compose - enabled as service
              kubectl
            ];

            # Enable virtualization with minimal footprint
            virtualisation.docker.enable = true;
            virtualisation.docker.autoPrune = {
              enable = true;
              dates = "weekly";
              flags = [ "--all" ];
            };

            # Disable libvirtd to reduce VM size (can be enabled per-deployment)
            # virtualisation.libvirtd.enable = true;

            users.users.nixos.extraGroups = [ "docker" ];

            # Disk space optimizations
            nix = {
              # Aggressive garbage collection
              gc = {
                automatic = true;
                dates = lib.mkForce "daily"; # Override any system defaults
                options = lib.mkForce "--delete-older-than 7d"; # Override any system defaults
              };
              # Store optimization
              optimise.automatic = true;
              # Reduce store size
              extraOptions = ''
                min-free = 536870912
                max-free = 1073741824
              '';
            };

            # Minimal documentation to reduce size
            documentation = {
              enable = lib.mkForce false;
              nixos.enable = lib.mkForce false;
              man.enable = lib.mkForce false;
            };

            # Reduce journal size
            services.journald.extraConfig = ''
              SystemMaxUse=100M
              RuntimeMaxUse=50M
            '';

            # Optimize boot for VMs
            boot = {
              # Use minimal initrd
              initrd.compressor = "zstd";
              # Reduce kernel modules
              kernelModules = lib.mkForce [
                "kvm-intel"
                "kvm-amd"
              ];
            };
          };
        };

        # Lightweight development environment
        development-minimal = {
          format = "qcow";
          extraConfig = {
            # Minimal development tools
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
              htop
              tree
              # Essential dev tools only
              nodejs
              python3
            ];

            # No virtualization to keep it minimal
            # Docker can be enabled on-demand post-deployment

            # Maximum space optimization
            nix = {
              gc = {
                automatic = true;
                dates = lib.mkForce "daily"; # Override any system defaults
                options = lib.mkForce "--delete-older-than 3d --delete-generations +5"; # Override any system defaults
              };
              optimise.automatic = true;
              extraOptions = ''
                min-free = 268435456
                max-free = 536870912
                keep-outputs = false
                keep-derivations = false
              '';
            };

            # Disable all documentation
            documentation.enable = lib.mkForce false;
            documentation.nixos.enable = lib.mkForce false;
            documentation.man.enable = lib.mkForce false;
            documentation.dev.enable = lib.mkForce false;

            # Minimal logging
            services.journald.extraConfig = ''
              SystemMaxUse=50M
              RuntimeMaxUse=25M
              Storage=volatile
            '';

            # Optimize for size
            boot = {
              initrd.compressor = "zstd";
              kernelModules = lib.mkForce [ ];
            };

            # Disable X11/GUI components - alternative to deprecated noXlibs
            services.xserver.enable = lib.mkForce false;
            fonts.enableDefaultPackages = lib.mkForce false;
          };
        };

        # Production server
        production-server = {
          format = "qcow";
          extraConfig = {
            # Security hardening
            security.apparmor.enable = true;
            security.auditd.enable = true;
            services.fail2ban.enable = true;

            # Server packages
            environment.systemPackages = with pkgs; [
              htop
              iotop
              nethogs
              rsync
              borgbackup
              nginx
              postgresql
            ];

            # Firewall configuration
            networking.firewall = {
              enable = true;
              allowedTCPPorts = [
                22
                80
                443
              ];
            };
          };
        };
      };

      # Generate standard platform images
      standardImages = lib.mapAttrs (_name: mkImage baseConfig) platformConfigs;

      # Generate specialized images
      specialImages = lib.mapAttrs (_name: mkImage baseConfig) specializedImages;

    in
    standardImages
    // specialImages
    // {
      # VM Builder Docker Image
      nixos-vm-builder-docker = pkgs.dockerTools.buildLayeredImage {
        name = "nixos-vm-builder";
        tag = "latest";
        contents = with pkgs; [
          # Core Nix tools for VM building
          nix
          git
          curl
          wget
          # VM management tools
          qemu
          libvirt
        ];
        config = {
          Cmd = [ "/bin/bash" ];
          WorkingDir = "/workspace";
          Env = [
            "NIX_PATH=nixpkgs=${nixpkgs}"
            "PATH=/bin"
          ];
        };
      };
    };

in
{
  # Export the factory function
  inherit mkDeploymentImages;

  # Pre-built images for common systems
  forAllSystems =
    systems: nixpkgs.lib.genAttrs systems (system: mkDeploymentImages { inherit system; });
}
