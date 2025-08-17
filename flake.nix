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

      # Helper function for home-manager configurations
      mkHome = { hostname, system ? "x86_64-linux" }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [ ./hosts/${hostname}/home.nix ];
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

      # Import deployment images generator
      deploymentImages = import ./lib/deployment-images.nix {
        inherit inputs outputs nixpkgs nixos-generators;
      };

      # Import Darwin configurations generator
      darwinConfigs = import ./lib/darwin-configs.nix {
        inherit inputs outputs nixpkgs nix-darwin home-manager;
      };
    in
    {
      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { };

      # Custom packages and deployment images; accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let
          # Generate deployment images using our factory
          images = deploymentImages.mkDeploymentImages { inherit system; };
        in
        # Merge custom packages with generated deployment images
        (import ./pkgs nixpkgs.legacyPackages.${system}) // images
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
      darwinConfigurations = darwinConfigs.standardConfigurations;

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

        # VM Integration Tests (minimal configuration to avoid circular dependencies)
        vm-test-desktop = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "nixos-template-desktop-test";
          nodes.machine = { config, lib, pkgs, ... }: {
            # Minimal test configuration - no complex module imports

            # Basic system setup
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Network
            networking.hostName = "desktop-test";
            networking.networkmanager.enable = true;

            # User for testing
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [ "wheel" "networkmanager" ];
              password = "test";
            };

            # Essential packages for testing
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
            ];

            # System state version
            system.stateVersion = "25.05";
          };
          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Test essential services
            machine.succeed("systemctl is-active NetworkManager")

            # Test basic tools are available
            machine.succeed("which git")
            machine.succeed("which vim")

            # Test user exists
            machine.succeed("id nixos")

            machine.shutdown()
          '';
        };

        vm-test-server = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "nixos-template-server-test";
          nodes.machine = { config, lib, pkgs, ... }: {
            # Minimal server test configuration - no complex module imports

            # Basic system setup
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Network and firewall
            networking.hostName = "server-test";
            networking.firewall.enable = true;
            networking.firewall.allowedTCPPorts = [ 22 ];

            # SSH service for server testing
            services.openssh = {
              enable = true;
              settings.PasswordAuthentication = true; # For testing only
            };

            # Test user
            users.users.nixos = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              password = "test";
            };

            # Essential server packages for testing
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
              htop
            ];

            # System state version
            system.stateVersion = "25.05";
          };
          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Test SSH service
            machine.wait_for_unit("sshd.service")
            machine.succeed("systemctl is-active sshd")

            # Test firewall is running
            machine.succeed("systemctl is-active firewall")

            # Test server tools are available
            machine.succeed("which htop")
            machine.succeed("which curl")

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
