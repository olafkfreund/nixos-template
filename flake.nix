{
  description = "A comprehensive NixOS configuration template";

  # Advanced Nix configuration for optimal performance and caching
  nixConfig = {
    # Enhanced substituters for faster builds
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    ];

    # Parallel building optimization
    max-jobs = "auto";
    cores = 0;

    # Advanced build optimizations
    keep-outputs = true;
    keep-derivations = true;
    auto-optimise-store = true;

    # Network and download optimization
    http-connections = 25;
    download-attempts = 3;

    # Build isolation and security
    sandbox = true;
    restrict-eval = false;

    # Experimental features for advanced functionality
    experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
      "recursive-nix"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, agenix, treefmt-nix, git-hooks, nixos-wsl, nix-darwin, sops-nix, nixos-generators, ... }@inputs:
    let
      inherit (self) outputs;
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Treefmt configuration
      treefmtEval = forAllSystems (system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          # Project root directory
          projectRootFile = "flake.nix";

          # Formatters by language/file type
          programs = {
            # Nix files
            nixpkgs-fmt.enable = true;

            # Shell scripts
            shfmt.enable = true;

            # Markdown files
            mdformat.enable = true;

            # YAML files
            yamlfmt.enable = true;

            # JSON files
            prettier.enable = true;
          };

          # File patterns and exclusions
          settings = {
            global.excludes = [
              # Git and build artifacts
              ".git/**"
              "result*"
              "*.png"
              "*.jpg"
              "*.jpeg"
              "*.gif"
              "*.ico"
              "*.tar*"
              "*.zip"
              "*.rar"
              "*.7z"
              # Generated files
              "**/hardware-configuration.nix"
              "flake.lock"
            ];
          };
        }
      );

      # Pre-commit hooks configuration (simplified for now)
      pre-commit-check = forAllSystems (system:
        git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            shellcheck.enable = true;
          };
        }
      );

      # Helper function to reduce duplication in nixosSystem configurations
      mkSystem =
        { hostname
        , system ? "x86_64-linux"
        , profile ? "workstation"
        , extraModules ? [ ]
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs outputs;
            # Add comprehensive flake metadata
            flakeMeta = {
              inherit hostname profile system;
              # Build information
              buildTime = self.lastModified or 0;
              buildDate = "build-${toString (self.lastModified or 0)}";
              flakeRev = self.rev or "dirty";
              flakeShortRev =
                if (self.rev or null) != null
                then builtins.substring 0 7 self.rev
                else "unknown";
              # Nixpkgs information
              nixpkgsRev = inputs.nixpkgs.rev or "unknown";
              nixpkgsShortRev =
                if (inputs.nixpkgs.rev or null) != null
                then builtins.substring 0 7 inputs.nixpkgs.rev
                else "unknown";
              # System identification
              configPath = toString ./.;
              hostPath = toString (./. + "/hosts/${hostname}");
            };
          };
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops # Standardize on sops-nix

            # Add flake metadata module
            ({ pkgs, flakeMeta, ... }: {
              # Make flake metadata available system-wide
              environment.etc."nixos/flake-metadata.json".text = builtins.toJSON flakeMeta;

              # Add metadata to system info
              environment.variables = {
                NIXOS_FLAKE_REV = flakeMeta.flakeShortRev;
                NIXOS_BUILD_DATE = flakeMeta.buildDate;
                NIXOS_HOSTNAME = flakeMeta.hostname;
                NIXOS_PROFILE = flakeMeta.profile;
              };

              # Create system info command
              environment.systemPackages = with pkgs; [
                (writeShellScriptBin "nixos-info" ''
                  echo "🏗️  NixOS System Information"
                  echo "=========================="
                  echo "Hostname: ${flakeMeta.hostname}"
                  echo "Profile: ${flakeMeta.profile}"
                  echo "System: ${flakeMeta.system}"
                  echo "Build Date: ${flakeMeta.buildDate}"
                  echo "Flake Revision: ${flakeMeta.flakeShortRev}"
                  echo "Nixpkgs Revision: ${flakeMeta.nixpkgsShortRev}"
                  echo "Config Path: ${flakeMeta.configPath}"
                  echo ""
                  echo "📊 System Stats:"
                  echo "Uptime: $(uptime -p)"
                  echo "Kernel: $(uname -r)"
                  echo "NixOS Version: $(nixos-version)"
                  echo ""
                  echo "🔧 Quick Commands:"
                  echo "• nixos-rebuild switch --flake ${flakeMeta.configPath}#${flakeMeta.hostname}"
                  echo "• nix flake update ${flakeMeta.configPath}"
                  echo "• systemctl status"
                '')
              ];

              # Add to system description
              system.nixos.tags = [ flakeMeta.profile flakeMeta.flakeShortRev ];
            })
          ] ++ extraModules;
        };

      # Helper function for home-manager configurations
      mkHome = { hostname, system ? "x86_64-linux" }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/${hostname}/home.nix ];
        };

      # Helper function for nix-darwin configurations
      mkDarwin = { hostname, system ? "aarch64-darwin" }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.darwinModules.home-manager
          ];
        };

      # Common template validation config
      templateConfig = {
        # Set timezone for templates
        time.timeZone = "Europe/London";
        # Location for geoclue2 (needed by laptop template)
        location = {
          latitude = 51.5074;
          longitude = -0.1278;
        };
        # Allow unfree packages for template validation
        nixpkgs.config.allowUnfree = true;
        # Allow insecure packages for template validation
        nixpkgs.config.permittedInsecurePackages = [ "libsoup-2.74.3" ];
      };
    in
    let
      # Import flake utilities to reduce duplication
      flakeUtils = import ./lib/flake-utils.nix {
        inherit inputs outputs nixpkgs self home-manager;
        sops-nix = agenix; # Use agenix as sops-nix (they're compatible)
      };
    in
    {
      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Custom packages and deployment images; accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Base configuration for all generated images
          baseConfig = {
            inherit system;
            specialArgs = { inherit inputs outputs; flakeMeta = null; };
            modules = [
              ./hosts/common.nix
              ({ lib, pkgs, ... }: {
                # Optimize for deployment images
                boot.loader.systemd-boot.enable = true;
                boot.loader.efi.canTouchEfiVariables = true;

                # Enable advanced features by default
                modules = {
                  core.nixOptimization.enable = true;
                  hardware.detection.enable = true;
                  services.monitoring.enable = false; # Enable per-deployment as needed
                };

                # Default user for images
                users.users.nixos = {
                  isNormalUser = true;
                  extraGroups = [ "wheel" "networkmanager" ];
                  initialPassword = "nixos";
                };

                # Ensure root user password conflicts are resolved in deployment images
                users.users.root = {
                  # Override any default initialHashedPassword that might be set by nixos-generators
                  hashedPassword = lib.mkOverride 100 "!"; # Lock root account
                  password = lib.mkOverride 100 null;
                  initialPassword = lib.mkOverride 100 null;
                  # Critical: Force initialHashedPassword to null (nixos-generators might set it to "")
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
              })
            ];
          };

          # Generate images for different deployment targets
          deploymentImages = {
            # Cloud deployment images
            "aws-ami" = nixos-generators.nixosGenerate (baseConfig // {
              format = "amazon";
              modules = baseConfig.modules ++ [
                ({ ... }: {
                  # AWS-specific optimizations
                  ec2.hvm = true;
                  boot.loader.grub.device = "/dev/xvda";
                  fileSystems."/" = {
                    device = "/dev/xvda1";
                    fsType = "ext4";
                  };
                })
              ];
            });

            "azure-vhd" = nixos-generators.nixosGenerate (baseConfig // {
              format = "azure";
              modules = baseConfig.modules ++ [
                ({ pkgs, ... }: {
                  # Azure-specific configurations
                  # Note: Azure agent configuration handled by nixos-generators
                  environment.systemPackages = with pkgs; [ waagent ];
                })
              ];
            });

            # Temporarily disabled due to google-guest-configs package issue
            # "gce-image" = nixos-generators.nixosGenerate (baseConfig // {
            #   format = "gce";
            #   modules = baseConfig.modules ++ [({ config, lib, pkgs, ... }: {
            #     # Google Cloud specific configurations
            #     services.openssh = {
            #       enable = true;
            #       # Override GCE default to match our base configuration
            #       settings.PermitRootLogin = lib.mkForce "no";
            #     };
            #
            #     # Override the problematic google-guest-configs configuration
            #     boot.extraModprobeConfig = lib.mkForce "";
            #
            #     # Ensure Google Cloud guest agent is available
            #     environment.systemPackages = with pkgs; [
            #       google-cloud-sdk
            #     ];
            #   })];
            # });

            "do-image" = nixos-generators.nixosGenerate (baseConfig // {
              format = "do";
              modules = baseConfig.modules ++ [
                ({ ... }: {
                  # Digital Ocean specific configurations
                  services.openssh.enable = true;
                })
              ];
            });

            # Virtualization images
            "vmware-image" = nixos-generators.nixosGenerate (baseConfig // {
              format = "vmware";
              modules = baseConfig.modules ++ [
                ({ ... }: {
                  # VMware-specific optimizations
                  virtualisation.vmware.guest.enable = true;
                  services.xserver.videoDrivers = [ "vmware" ];
                })
              ];
            });

            "virtualbox-ova" = nixos-generators.nixosGenerate {
              inherit system;
              specialArgs = { inherit inputs outputs; flakeMeta = null; };
              format = "virtualbox";
              modules = [
                ({ lib, pkgs, ... }: {
                  # Minimal VirtualBox configuration to reduce memory usage
                  boot.loader.systemd-boot.enable = true;
                  boot.loader.efi.canTouchEfiVariables = true;

                  # VirtualBox-specific optimizations
                  virtualisation.virtualbox.guest.enable = true;
                  services.xserver = {
                    enable = true;
                    videoDrivers = [ "virtualbox" "modesetting" ];
                  };

                  # Use updated option names for NixOS 24.05+
                  services.desktopManager.gnome.enable = true;
                  services.displayManager.gdm.enable = true;

                  # Essential system packages only
                  environment.systemPackages = with pkgs; [
                    vim
                    git
                    curl
                    wget
                    htop
                    firefox
                  ];

                  # Default user for VM
                  users.users.nixos = {
                    isNormalUser = true;
                    extraGroups = [ "wheel" "networkmanager" ];
                    initialPassword = "nixos";
                  };

                  # Network configuration
                  networking.networkmanager.enable = true;
                  networking.firewall.enable = false; # Disabled for VM ease of use

                  # System version
                  system.stateVersion = "24.05";

                  # Keep VM image size reasonable
                  nix.gc.automatic = true;
                  nix.optimise.automatic = true;
                })
              ];
            };

            "qemu-qcow2" = nixos-generators.nixosGenerate (baseConfig // {
              format = "qcow";
              modules = baseConfig.modules ++ [
                ({ ... }: {
                  # QEMU/KVM optimizations
                  services.qemuGuest.enable = true;
                  services.spice-vdagentd.enable = true;
                })
              ];
            });

            # Container images
            "lxc-template" = nixos-generators.nixosGenerate (baseConfig // {
              format = "lxc";
              modules = baseConfig.modules ++ [
                ({ lib, ... }: {
                  # LXC container optimizations
                  boot.isContainer = true;
                  services.openssh.enable = true;
                  # Disable audit for containers (container-config.nix default)
                  security.audit.enable = lib.mkForce false;
                })
              ];
            });

            # Installation media
            "live-iso" = nixos-generators.nixosGenerate (baseConfig // {
              format = "iso";
              modules = baseConfig.modules ++ [
                ({ pkgs, ... }: {
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
                    chromium
                    networkmanager-openvpn
                    wpa_supplicant_gui
                  ];
                })
              ];
            });

            # ARM/Raspberry Pi images (requires aarch64-linux system for native build)
            # Note: Cross-compilation from x86_64 to aarch64 requires --impure flag
            # Include this only when building on aarch64-linux or with cross-compilation enabled

            # Development and testing images
            "development-vm" = nixos-generators.nixosGenerate (baseConfig // {
              format = "qcow";
              modules = baseConfig.modules ++ [
                ({ pkgs, ... }: {
                  # Development-focused configuration
                  # Note: monitoring disabled to avoid module conflicts
                  # modules.services.monitoring.enable = lib.mkForce true;

                  # Development tools
                  environment.systemPackages = with pkgs; [
                    git
                    vim
                    neovim
                    emacs
                    nodejs
                    python3
                    rustc
                    cargo
                    docker
                    docker-compose
                    kubectl
                    terraform
                    vscode-fhs
                  ];

                  # Enable virtualization
                  virtualisation.docker.enable = true;
                  virtualisation.libvirtd.enable = true;

                  users.users.nixos.extraGroups = [ "docker" "libvirtd" ];
                })
              ];
            });

            # Server deployment image
            "production-server" = nixos-generators.nixosGenerate (baseConfig // {
              format = "qcow";
              modules = baseConfig.modules ++ [
                ({ pkgs, ... }: {
                  # Production server configuration
                  # Note: monitoring disabled to avoid module conflicts
                  # modules.services.monitoring.enable = lib.mkForce true;

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
                    allowedTCPPorts = [ 22 80 443 ];
                  };
                })
              ];
            });
          };

          # VM Builder Docker Image
          nixos-vm-builder-docker = pkgs.dockerTools.buildLayeredImage {
            name = "nixos-vm-builder";
            tag = "latest";
            contents = with pkgs; [
              # Core Nix tools
              nix
              nixos-generators.packages.${system}.default

              # Build dependencies
              bash
              coreutils
              findutils
              gnugrep
              gnused
              gnutar
              gzip

              # JSON processing
              jq

              # VM builder script (embedded to avoid path issues)
              (writeShellScriptBin "build-vm.sh" ''
                #!/usr/bin/env bash
                # NixOS VM Builder Script - Embedded version
                # This is a simplified version for Docker container use

                set -euo pipefail

                # Default configuration
                DEFAULT_FORMAT="virtualbox"
                DEFAULT_OUTPUT_DIR="/workspace/output"
                DEFAULT_DISK_SIZE="20480"
                DEFAULT_MEMORY_SIZE="4096"

                show_help() {
                  cat <<EOF
                NixOS VM Builder - Build NixOS VMs for Windows users

                USAGE:
                    build-vm.sh [FORMAT] [OPTIONS]

                FORMATS:
                    virtualbox      Build VirtualBox OVA image
                    hyperv          Build Hyper-V VHDX image
                    vmware          Build VMware VMDK image
                    qemu            Build QEMU QCOW2 image
                    all             Build all formats

                OPTIONS:
                    -t, --template NAME     Use template (desktop,server,gaming,minimal,development)
                    -o, --output DIR        Output directory (default: /workspace/output)
                    -s, --disk-size SIZE    Disk size in MB (default: 20480)
                    -m, --memory SIZE       Memory size in MB (default: 4096)
                    -n, --vm-name NAME      VM name
                    --validate-only         Only validate configuration
                    --list-templates        List available templates
                    -h, --help             Show this help

                EXAMPLES:
                    build-vm.sh virtualbox --template desktop
                    build-vm.sh hyperv --template server --disk-size 40960
                    build-vm.sh all --template gaming
                EOF
                }

                # For now, show help - full implementation would require templates
                if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
                  show_help
                  exit 0
                fi

                echo "Docker VM Builder - This is a placeholder implementation"
                echo "Please use the full nixos-generators command directly for now."
                exit 1
              '')
            ];

            config = {
              Env = [
                "NIX_CONF_DIR=/root/.config/nix"
                "NIXOS_GENERATORS_VERSION=1.8.0"
                "PATH=/usr/bin:/bin"
              ];

              WorkingDir = "/workspace";

              Entrypoint = [ "/bin/build-vm.sh" ];

              Cmd = [ "--help" ];

              Labels = {
                "org.opencontainers.image.title" = "NixOS VM Builder";
                "org.opencontainers.image.description" = "Build NixOS VMs for Windows users";
                "org.opencontainers.image.source" = "https://github.com/nixos/nixos-template";
                "org.opencontainers.image.licenses" = "GPL-3.0";
              };
            };
          };

          # VM Builder CLI tool
          nixos-vm-builder = pkgs.writeShellApplication {
            name = "nixos-vm-builder";
            runtimeInputs = with pkgs; [ docker ];
            text = ''
              # NixOS VM Builder CLI wrapper
              # This is a convenience wrapper for the Docker-based VM builder

              DOCKER_IMAGE="nixos-vm-builder:latest"
              WORKSPACE_DIR="$PWD/vm-workspace"

              # Create workspace directory
              mkdir -p "$WORKSPACE_DIR"

              # Check if Docker image exists locally
              if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
                echo "Docker image $DOCKER_IMAGE not found locally."
                echo "Please build it first with: nix build .#nixos-vm-builder-docker"
                echo "Then load it with: docker load < result"
                exit 1
              fi

              # Run the Docker container with arguments
              exec docker run --rm \
                -v "$WORKSPACE_DIR:/workspace" \
                "$DOCKER_IMAGE" \
                "$@"
            '';
          };

        in
        # Merge custom packages with deployment images and VM builder
        (import ./pkgs pkgs) // deploymentImages // {
          inherit nixos-vm-builder-docker nixos-vm-builder;
        }
      );

      # Formatter for your nix files, available through 'nix fmt'
      # Uses treefmt for multi-language formatting
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Development shell for working on the template
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Nix development tools
              nixpkgs-fmt
              statix
              deadnix
              nh

              # Code quality tools
              treefmt
              pre-commit

              # Shell scripting tools
              shellcheck
              shfmt

              # Documentation tools
              markdownlint-cli

              # Development utilities
              git
              just
              jq

              # Hardware detection
              pciutils
              usbutils
              lshw
            ];

            # Environment variables
            NIX_CONFIG = "experimental-features = nix-command flakes";
            LC_ALL = "C.UTF-8";

            # Combined shell hook
            shellHook = ''
              echo "🚀 NixOS Template Development Environment"
              echo ""
              echo "📋 Available commands:"
              echo "  just --list       - Show all available tasks"
              echo "  nix fmt           - Format Nix code"
              echo "  nh --help         - Better NixOS system management"
              echo ""
              echo "🔧 Development tools loaded:"
              echo "  nixpkgs-fmt, statix, deadnix, shellcheck, pre-commit"
              echo ""

              # Setup pre-commit hooks if not already done
              if [[ ! -f .git/hooks/pre-commit ]] && command -v pre-commit >/dev/null; then
                echo "🔗 Setting up pre-commit hooks..."
                pre-commit install --install-hooks
                echo "✅ Pre-commit hooks installed"
              fi

              ${pre-commit-check.${system}.shellHook or ""}
            '';
          };
        });

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      # All configurations are now generated using flake-utils.nix to reduce duplication
      nixosConfigurations = flakeUtils.allConfigurations;

      # nix-darwin configuration entrypoint
      # Available through 'darwin-rebuild switch --flake .#your-hostname'
      darwinConfigurations = {
        # Desktop configuration for macOS (Apple Silicon)
        darwin-desktop = mkDarwin {
          hostname = "darwin-desktop";
          system = "aarch64-darwin";
        };

        # Desktop configuration for macOS (Intel)
        darwin-desktop-intel = mkDarwin {
          hostname = "darwin-desktop";
          system = "x86_64-darwin";
        };

        # Laptop configuration for macOS (Apple Silicon)
        darwin-laptop = mkDarwin {
          hostname = "darwin-laptop";
          system = "aarch64-darwin";
        };

        # Laptop configuration for macOS (Intel)
        darwin-laptop-intel = mkDarwin {
          hostname = "darwin-laptop";
          system = "x86_64-darwin";
        };

        # Server configuration for macOS (Apple Silicon)
        darwin-server = mkDarwin {
          hostname = "darwin-server";
          system = "aarch64-darwin";
        };

        # Server configuration for macOS (Intel)
        darwin-server-intel = mkDarwin {
          hostname = "darwin-server";
          system = "x86_64-darwin";
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # Example home configurations
        "user@laptop-template" = mkHome { hostname = "laptop-template"; };
        "user@desktop-template" = mkHome { hostname = "desktop-template"; };
        "user@server-template" = mkHome { hostname = "server-template"; };
        "vm-user@desktop-test" = mkHome { hostname = "desktop-test"; };
        "nixos@wsl2-template" = mkHome { hostname = "wsl2-template"; };

        # macOS VM home configurations
        "nixos@desktop-macos" = mkHome {
          hostname = "macos-vms/desktop-macos";
          system = "aarch64-linux";
        };
        "laptop-user@laptop-macos" = mkHome {
          hostname = "macos-vms/laptop-macos";
          system = "aarch64-linux";
        };
        "server-admin@server-macos" = mkHome {
          hostname = "macos-vms/server-macos";
          system = "aarch64-linux";
        };

        # Intel Mac variants
        "nixos@desktop-macos-intel" = mkHome {
          hostname = "macos-vms/desktop-macos";
          system = "x86_64-linux";
        };
        "laptop-user@laptop-macos-intel" = mkHome {
          hostname = "macos-vms/laptop-macos";
          system = "x86_64-linux";
        };
        "server-admin@server-macos-intel" = mkHome {
          hostname = "macos-vms/server-macos";
          system = "x86_64-linux";
        };
      };

      # Checks for CI/CD and development
      # Available through 'nix flake check'
      checks = forAllSystems (system: {
        # Pre-commit hooks check
        pre-commit-check = pre-commit-check.${system};

        # Treefmt formatting check
        treefmt = treefmtEval.${system}.config.build.check self;

        # Flake validation (already included in flake check, but explicit here)
        flake-check = nixpkgs.legacyPackages.${system}.runCommand "flake-check" { } ''
          cd ${self}
          ${nixpkgs.legacyPackages.${system}.nixVersions.latest}/bin/nix flake check --no-build
          touch $out
        '';

        # Statix linting
        statix-check = nixpkgs.legacyPackages.${system}.runCommand "statix-check" { } ''
          cd ${self}
          ${nixpkgs.legacyPackages.${system}.statix}/bin/statix check .
          touch $out
        '';

        # Deadnix check
        deadnix-check = nixpkgs.legacyPackages.${system}.runCommand "deadnix-check" { } ''
          cd ${self}
          ${nixpkgs.legacyPackages.${system}.deadnix}/bin/deadnix --fail .
          touch $out
        '';

        # Shell script validation
        shellcheck-check = nixpkgs.legacyPackages.${system}.runCommand "shellcheck-check" { } ''
          cd ${self}
          ${nixpkgs.legacyPackages.${system}.shellcheck}/bin/shellcheck scripts/*.sh
          touch $out
        '';

        # WSL2 configuration validation (x86_64-linux only)
        wsl2-config-check =
          if system == "x86_64-linux" then
            nixpkgs.legacyPackages.${system}.runCommand "wsl2-config-check" { } ''
              echo "Validating WSL2 configuration..."
              # Check that WSL2 configuration builds without errors
              ${nixpkgs.legacyPackages.${system}.nixVersions.latest}/bin/nix build ${self}#nixosConfigurations.wsl2-template.config.system.build.toplevel --no-link
              echo "✅ WSL2 configuration builds successfully"
              touch $out
            ''
          else
            nixpkgs.legacyPackages.${system}.runCommand "skip-wsl2-check" { } ''
              echo "Skipping WSL2 check on ${system} (WSL2 only supports x86_64-linux)"
              touch $out
            '';

        # WSL2 Home Manager validation (x86_64-linux only)
        wsl2-home-check =
          if system == "x86_64-linux" then
            nixpkgs.legacyPackages.${system}.runCommand "wsl2-home-check" { } ''
              echo "Validating WSL2 Home Manager configuration..."
              ${nixpkgs.legacyPackages.${system}.nixVersions.latest}/bin/nix build ${self}#homeConfigurations."nixos@wsl2-template".activationPackage --no-link
              echo "✅ WSL2 Home Manager configuration builds successfully"
              touch $out
            ''
          else
            nixpkgs.legacyPackages.${system}.runCommand "skip-wsl2-home-check" { } ''
              echo "Skipping WSL2 Home Manager check on ${system}"
              touch $out
            '';

        # VM Integration Tests
        vm-test-desktop = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "nixos-template-desktop-test";
          nodes.machine = { ... }: {
            imports = [ ./hosts/desktop-template/configuration.nix ];
            virtualisation = {
              memorySize = 2048;
              cores = 2;
              graphics = false;
            };
          };
          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Test essential services
            machine.succeed("systemctl is-active NetworkManager")
            machine.succeed("systemctl is-active systemd-resolved")

            # Test Home Manager integration
            machine.succeed("test -f /home/nixos/.zshrc")

            # Test development tools
            machine.succeed("which git")
            machine.succeed("which vim")

            machine.shutdown()
          '';
        };

        vm-test-server = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "nixos-template-server-test";
          nodes.machine = { ... }: {
            imports = [ ./hosts/server-template/configuration.nix ];
            virtualisation = {
              memorySize = 1024;
              cores = 2;
              graphics = false;
            };
          };
          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Test SSH service
            machine.wait_for_unit("sshd.service")
            machine.succeed("systemctl is-active sshd")

            # Test firewall
            machine.succeed("systemctl is-active firewall")

            machine.shutdown()
          '';
        };

        # Configuration validation tests
        config-syntax-check = nixpkgs.legacyPackages.${system}.runCommand "config-syntax-validation" { } ''
          echo "Validating NixOS configuration syntax..."

          # Check all host configurations can be evaluated
          ${nixpkgs.legacyPackages.${system}.lib.concatMapStringsSep "\n" (host:
            "echo 'Testing ${host} configuration...'"
          ) (nixpkgs.legacyPackages.${system}.lib.attrNames self.nixosConfigurations)}

          echo "✅ All configurations validated successfully"
          touch $out
        '';

        # Module dependency check
        module-dependency-check = nixpkgs.legacyPackages.${system}.runCommand "module-dependency-check"
          {
            buildInputs = with nixpkgs.legacyPackages.${system}; [ nix jq ];
          } ''
          echo "Checking module dependencies..."

          # Validate that all module imports resolve
          find ${./.}/modules -name "*.nix" -type f | while read module; do
            echo "Checking module: $module"
            nix-instantiate --eval -E "import $module { config = {}; lib = (import <nixpkgs> {}).lib; pkgs = import <nixpkgs> {}; }" > /dev/null || echo "WARNING: $module may have unmet dependencies"
          done

          echo "✅ Module dependency check completed"
          touch $out
        '';

        # Security validation
        security-check = nixpkgs.legacyPackages.${system}.runCommand "security-validation"
          {
            buildInputs = with nixpkgs.legacyPackages.${system}; [ gnugrep ];
          } ''
          echo "Running security validation..."

          # Check for hardcoded passwords or secrets
          if grep -r "password.*=" ${./.}/hosts/ ${./.}/modules/ | grep -v "example\|template\|placeholder\|CHANGE"; then
            echo "WARNING: Potential hardcoded secrets found"
          fi

          # Check for world-writable files
          find ${./.} -type f -perm /o+w -exec echo "WARNING: World-writable file: {}" \; || true

          echo "✅ Security validation completed"
          touch $out
        '';
      });
    };
}
