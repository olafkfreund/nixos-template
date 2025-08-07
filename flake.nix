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
  };

  outputs = { self, nixpkgs, home-manager, agenix, treefmt-nix, git-hooks, ... }@inputs:
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
              "*.png" "*.jpg" "*.jpeg" "*.gif" "*.ico"
              "*.tar*" "*.zip" "*.rar" "*.7z"
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

      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # Example home configurations
        "user@laptop-template" = mkHome { username = "user"; hostname = "laptop-template"; };
        "user@desktop-template" = mkHome { username = "user"; hostname = "desktop-template"; };
        "user@server-template" = mkHome { username = "user"; hostname = "server-template"; };
        "vm-user@desktop-test" = mkHome { username = "vm-user"; hostname = "desktop-test"; };
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
      });
    };
}
