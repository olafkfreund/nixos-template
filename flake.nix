{
  description = "A comprehensive NixOS configuration template";

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
  };

  outputs = { self, nixpkgs, home-manager, agenix, treefmt-nix, git-hooks, nixos-wsl, nix-darwin, ... }@inputs:
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
      mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
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
    {
      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # Custom packages; acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

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
      nixosConfigurations = {
        # Template configurations (examples, not directly usable)
        laptop-template = mkSystem {
          hostname = "laptop-template";
          extraModules = [ templateConfig ];
        };

        desktop-template = mkSystem {
          hostname = "desktop-template";
          extraModules = [ templateConfig ];
        };

        server-template = mkSystem {
          hostname = "server-template";
          extraModules = [ templateConfig ];
        };

        # WSL2 template configuration
        wsl2-template = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/wsl2-template/configuration.nix
            nixos-wsl.nixosModules.wsl
            home-manager.nixosModules.home-manager
            agenix.nixosModules.default
            templateConfig
          ];
        };

        # Example VM configurations  
        qemu-vm = mkSystem { hostname = "qemu-vm"; };
        microvm = mkSystem { hostname = "microvm"; };
        desktop-test = mkSystem {
          hostname = "desktop-test";
          extraModules = [ templateConfig ];
        };

        # Preset system test configurations
        test-workstation = mkSystem { hostname = "test-workstation"; };
        test-gaming = mkSystem { hostname = "test-gaming"; };
        test-server = mkSystem { hostname = "test-server"; };

        # Custom installer ISO configurations
        # Build with: nix build .#nixosConfigurations.installer-minimal.config.system.build.isoImage
        installer-minimal = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/minimal-installer.nix
            templateConfig
          ];
        };

        installer-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/desktop-installer.nix
            templateConfig
          ];
        };

        installer-preconfigured = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/installer-isos/preconfigured-installer.nix
            templateConfig
          ];
        };

        # macOS VM configurations - optimized for UTM/QEMU on Mac
        # Build with: nix build .#nixosConfigurations.desktop-macos.config.system.build.vm
        desktop-macos = mkSystem {
          hostname = "macos-vms/desktop-macos";
          system = "aarch64-linux"; # Apple Silicon default, can override for x86_64
          extraModules = [ templateConfig ];
        };

        laptop-macos = mkSystem {
          hostname = "macos-vms/laptop-macos";
          system = "aarch64-linux";
          extraModules = [ templateConfig ];
        };

        server-macos = mkSystem {
          hostname = "macos-vms/server-macos";
          system = "aarch64-linux";
          extraModules = [ templateConfig ];
        };

        # macOS VM configurations for Intel Macs (x86_64)
        desktop-macos-intel = mkSystem {
          hostname = "macos-vms/desktop-macos";
          system = "x86_64-linux";
          extraModules = [ templateConfig ];
        };

        laptop-macos-intel = mkSystem {
          hostname = "macos-vms/laptop-macos";
          system = "x86_64-linux";
          extraModules = [ templateConfig ];
        };

        server-macos-intel = mkSystem {
          hostname = "macos-vms/server-macos";
          system = "x86_64-linux";
          extraModules = [ templateConfig ];
        };

        # macOS installer ISO configurations
        # Build with: nix build .#nixosConfigurations.installer-desktop-macos.config.system.build.isoImage
        installer-desktop-macos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux"; # ISOs typically x86_64 for compatibility
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/macos-isos/desktop-iso-macos.nix
            templateConfig
          ];
        };

        installer-minimal-macos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/macos-isos/minimal-iso-macos.nix
            templateConfig
          ];
        };

        # macOS installer ISOs for Apple Silicon (aarch64)
        installer-desktop-macos-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/macos-isos/desktop-iso-macos.nix
            templateConfig
          ];
        };

        installer-minimal-macos-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./hosts/macos-isos/minimal-iso-macos.nix
            templateConfig
          ];
        };

      };

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
      });
    };
}
