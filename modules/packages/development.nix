# Development tools package collection
# Programming languages, IDEs, containerization, and development utilities
{ pkgs, lib, config, ... }:

{
  options.modules.packages.development = {
    enable = lib.mkEnableOption "development tools package collection";

    includeLanguages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include programming language runtimes and compilers";
    };

    includeContainers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include Docker, Kubernetes, and container tools";
    };

    includeCloud = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include cloud platform tools (AWS, GCP, Azure)";
    };

    includeDatabase = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include database tools and clients";
    };
  };

  config = lib.mkIf config.modules.packages.development.enable {
    environment.systemPackages = with pkgs; [
      # Code editors and IDEs
      vscode
      neovim
      jetbrains.idea-community

      # Version control
      git
      git-lfs
      gh # GitHub CLI
      gitui # TUI for git

      # Build tools
      gnumake
      cmake
      ninja

      # API and testing tools
      curl
      httpie
      postman

      # Documentation
      pandoc

      # Terminal utilities
      tmux
      screen

      # System monitoring for development
      btop
      htop
      iotop
      nethogs

      # Text processing
      ripgrep
      fd
      jq
      yq

      # Performance tools
      hyperfine # Benchmarking
      valgrind
      gdb
      strace

    ] ++ lib.optionals config.modules.packages.development.includeLanguages [
      # Programming languages
      nodejs_20
      python311
      python311Packages.pip
      python311Packages.virtualenv
      go
      rustc
      cargo
      gcc
      clang
      openjdk17

      # Language servers
      nixd # Nix LSP
      nil # Alternative Nix LSP

    ] ++ lib.optionals config.modules.packages.development.includeContainers [
      # Container tools
      docker
      docker-compose
      podman
      kubernetes
      kubectl
      k9s # Kubernetes TUI
      helm

    ] ++ lib.optionals config.modules.packages.development.includeCloud [
      # Cloud platform tools
      awscli2
      google-cloud-sdk
      azure-cli
      terraform
      terragrunt

    ] ++ lib.optionals config.modules.packages.development.includeDatabase [
      # Database tools
      dbeaver-bin
      postgresql_15 # Includes psql client
      mysql80 # Includes mysql client
      sqlite
      redis
      mongodb-tools
    ];

    # Development environment configuration
    programs = {
      # Enable direnv for project-specific environments
      direnv = {
        enable = lib.mkDefault true;
        nix-direnv.enable = lib.mkDefault true;
      };

      # Git configuration at system level
      git = {
        enable = lib.mkDefault true;

        config = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core.editor = "vim";
          merge.conflictstyle = "diff3";
        };
      };
    };

    # Development services
    virtualisation = lib.mkIf config.modules.packages.development.includeContainers {
      docker = {
        enable = lib.mkDefault true;
        enableOnBoot = lib.mkDefault false; # Start manually to save resources
      };
    };

    # User groups for development
    users.users = lib.mkIf config.modules.packages.development.includeContainers {
      # Add main user to docker group (requires user to be defined)
      # This will be overridden by individual host configurations
    };

    # Firewall rules for development
    networking.firewall = {
      # Common development ports (can be overridden per host)
      allowedTCPPorts = [
        3000
        8000
        8080
        8443 # Web development
        5432 # PostgreSQL
        3306 # MySQL
        6379 # Redis
        27017 # MongoDB
      ];
    };

    # Environment variables for development
    environment.sessionVariables = {
      # Node.js
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";

      # Go
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";

      # Rust
      CARGO_HOME = "$HOME/.cargo";

      # Python
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";

      # Development optimizations
      DOCKER_BUILDKIT = "1";
      COMPOSE_DOCKER_CLI_BUILD = "1";
    };
  };
}
