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
    ];
  };

  inputs = {
    # Tracks the current NixOS stable release. Stable gives near-complete binary
    # cache coverage and matches the `system.stateVersion` used by the hosts here.
    #
    # Want bleeding edge instead? Change both of the following to:
    #   nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    #   home-manager.url = "github:nix-community/home-manager";
    # ...then bump `system.stateVersion` only when you actually upgrade releases.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
    # niri has no module in nixpkgs or home-manager, so its config would
    # otherwise have to be a hand-written KDL string. This provides both.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      agenix,
      treefmt-nix,
      git-hooks,
      nix-darwin,
      nixos-generators,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      # i686-linux is deliberately absent: git-hooks.nix does not provide
      # `lib.i686-linux`, so `checks.i686-linux.pre-commit-check` fails to
      # evaluate and `nix flake show --all-systems` errors out. Nothing in this
      # template targets 32-bit x86, and nixpkgs support for it is minimal.
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Treefmt configuration
      treefmtEval = forAllSystems (
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          # Project root directory
          projectRootFile = "flake.nix";

          # Formatters by language/file type
          programs = {
            # Nix files. nixfmt is the official Nix formatter (RFC 166);
            # nixpkgs-fmt is archived upstream.
            nixfmt.enable = true;

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
              "site/**"
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
      pre-commit-check = forAllSystems (
        system:
        git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style = {
              enable = true;
              # Keep this in step with treefmt's global.excludes above: generated
              # hardware-configuration.nix files are owned by
              # nixos-generate-config, not by us, so neither tool reformats them.
              excludes = [ ".*hardware-configuration\\.nix$" ];
            };
            statix.enable = true;
            shellcheck.enable = true;
          };
        }
      );

      # Helper function for home-manager configurations
      mkHome =
        {
          hostname,
          system ? "x86_64-linux",
        }:
        home-manager.lib.homeManagerConfiguration {
          # `import nixpkgs` rather than `legacyPackages` so that allowUnfree can
          # be set. The profiles here pull in unfree packages such as vscode, and
          # the NixOS-integrated hosts already allow them; without this the
          # standalone `homeConfigurations.*` outputs simply fail to evaluate.
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            inputs.niri.homeModules.niri
            ./hosts/${hostname}/home.nix
          ];
        };

      # Import flake utilities to reduce duplication
      flakeUtils = import ./lib/flake-utils.nix {
        inherit
          inputs
          outputs
          nixpkgs
          self
          home-manager
          agenix
          ;
      };

      # Import deployment images generator
      deploymentImages = import ./lib/deployment-images.nix {
        inherit
          inputs
          outputs
          nixpkgs
          nixos-generators
          ;
      };

      # Import Darwin configurations generator
      darwinConfigs = import ./lib/darwin-configs.nix {
        inherit
          inputs
          outputs
          nixpkgs
          nix-darwin
          home-manager
          ;
      };
    in
    {
      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { };

      # Custom packages and deployment images; accessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (
        system:
        let
          # Deployment images are NixOS systems, so they only make sense on
          # Linux. Generating them for *-darwin built a nixosSystem with a
          # Darwin pkgs set, which then tried to set the nix-darwin-only option
          # `networking.computerName` on a NixOS configuration and failed to
          # evaluate. `nix flake check` never caught it because it skips the
          # darwin systems; only `nix flake show --all-systems` reaches here.
          images = nixpkgs.lib.optionalAttrs (nixpkgs.lib.hasSuffix "-linux" system) (
            deploymentImages.mkDeploymentImages { inherit system; }
          );
        in
        # Merge custom packages with generated deployment images
        (import ./pkgs nixpkgs.legacyPackages.${system}) // images
      );
      # Formatter for your nix files, available through 'nix fmt'
      # Uses treefmt for multi-language formatting
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # Development shell for working on the template
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Nix development tools
              nixfmt
              nixd # Nix language server: option completion + docs in your editor
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
              fzf
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
              echo "  nixfmt, statix, deadnix, shellcheck, pre-commit"
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
        }
      );

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      # All configurations are now generated using flake-utils.nix to reduce duplication
      nixosConfigurations = flakeUtils.allConfigurations // {

        # ─────────────────────────────────────────────────────────────────────
        #  ADD YOUR OWN HOSTS HERE
        # ─────────────────────────────────────────────────────────────────────
        #  1. cp -r hosts/desktop-template hosts/my-desktop
        #  2. sudo nixos-generate-config --show-hardware-config \
        #       > hosts/my-desktop/hardware-configuration.nix
        #  3. Uncomment and edit one of the lines below.
        #  4. sudo nixos-rebuild switch --flake .#my-desktop
        #
        #  `profile` is metadata used by modules/core/system-identification.nix;
        #  it does not by itself pull in packages. See docs/HOST-TEMPLATES.md.
        #
        # my-desktop = flakeUtils.mkSystem {
        #   hostname = "my-desktop";           # must match the hosts/ directory
        #   profile = "workstation";           # workstation, server, laptop, gaming, development, minimal
        # };
        #
        # my-server = flakeUtils.mkSystem {
        #   hostname = "my-server";
        #   profile = "server";
        #   system = "aarch64-linux";          # defaults to x86_64-linux
        #   extraModules = [ ./hosts/my-server/services.nix ];
        # };
      };

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
      checks = forAllSystems (
        system:
        {
          # Pre-commit hooks check
          pre-commit-check = pre-commit-check.${system};

          # Treefmt formatting check
          treefmt = treefmtEval.${system}.config.build.check self;

          # NOTE: there is deliberately no "run `nix flake check` inside a check"
          # derivation here. Nix cannot invoke itself inside the build sandbox
          # (no daemon, no network), so such a check can only ever fail. The
          # per-host evaluation it was meant to provide already happens: `nix flake
          # check` evaluates every entry in `nixosConfigurations` natively.

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

          # Shell script validation. `-S warning` keeps real problems failing the
          # build while ignoring info-level notes such as SC2016, which fires on
          # help text that deliberately prints a literal `$USER`.
          shellcheck-check = nixpkgs.legacyPackages.${system}.runCommand "shellcheck-check" { } ''
            cd ${self}
            ${nixpkgs.legacyPackages.${system}.shellcheck}/bin/shellcheck scripts/*.sh
            touch $out
          '';

          # VM Integration Tests (minimal configuration to avoid circular dependencies)
          vm-test-desktop = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
            name = "nixos-template-desktop-test";
            nodes.machine = { pkgs, ... }: {
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
                extraGroups = [
                  "wheel"
                  "networkmanager"
                ];
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
              system.stateVersion = "26.05";
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
            nodes.machine = { pkgs, ... }: {
              # Minimal server test configuration - no complex module imports

              # Basic system setup
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;

              # Network and firewall
              networking = {
                hostName = "server-test";
                firewall = {
                  enable = true;
                  allowedTCPPorts = [ 22 ];
                };
              };

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
              system.stateVersion = "26.05";
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

          # NOTE: `config-syntax-check`, `module-dependency-check` and
          # `security-check` used to live here. Each one ended in an unconditional
          # `echo "✅ ..."; touch $out`, so all three passed no matter what they
          # found — `config-syntax-check` only echoed host names without evaluating
          # anything. A check that cannot fail is worse than no check, because it
          # reads as coverage. Real evaluation coverage comes from `nix flake
          # check` walking `nixosConfigurations`, and real linting from
          # statix/deadnix/shellcheck above.
        }
        # Build the WSL2 outputs for real, by referring to the derivations
        # directly. (The previous version shelled out to `nix build` inside a
        # sandboxed derivation, which can never work.)
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          wsl2-config = self.nixosConfigurations.wsl2-template.config.system.build.toplevel;
          wsl2-home = self.homeConfigurations."nixos@wsl2-template".activationPackage;
        }
      );
    };
}
