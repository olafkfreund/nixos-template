# Development Home Manager profile
# Configuration for software development environments
{ lib, pkgs, ... }:

{
  # Import base configuration
  imports = [ ./base.nix ];

  # Home configuration
  home = {
    # Development packages
    packages = [
      # Version control
      pkgs.git-lfs
      pkgs.gh # GitHub CLI
      pkgs.gitui # TUI for git

      # Editors and IDEs
      pkgs.neovim
      pkgs.vscode

      # Language servers and tools
      pkgs.nixd # Nix LSP
      pkgs.nil # Alternative Nix LSP

      # Programming languages
      pkgs.nodejs_20
      pkgs.python311
      pkgs.python311Packages.pip
      pkgs.python311Packages.virtualenv
      pkgs.go
      pkgs.rustc
      pkgs.cargo

      # Build tools
      pkgs.gnumake
      pkgs.cmake
      pkgs.gcc
      pkgs.clang

      # Database tools
      pkgs.postgresql_15
      pkgs.sqlite

      # API tools
      pkgs.httpie
      pkgs.postman

      # Containerization
      pkgs.docker
      pkgs.docker-compose
      pkgs.kubernetes
      pkgs.kubectl
      pkgs.k9s # Kubernetes TUI

      # Cloud tools
      pkgs.awscli2
      pkgs.google-cloud-sdk
      pkgs.terraform

      # Documentation
      pkgs.pandoc

      # Debugging and profiling
      pkgs.gdb
      pkgs.valgrind
      pkgs.strace

      # Network tools
      pkgs.wireshark
      pkgs.nmap

      # Text processing
      pkgs.ripgrep
      pkgs.fd
      pkgs.jq
      pkgs.yq

      # File synchronization
      pkgs.rsync
      pkgs.rclone

      # Performance monitoring
      pkgs.hyperfine # Benchmarking
    ];

    # Development path additions
    sessionPath = [
      "$HOME/.npm-global/bin"
      "$HOME/.cargo/bin"
      "$HOME/go/bin"
      "$HOME/.local/bin"
    ];

    # Development environment variables
    sessionVariables = {
      EDITOR = lib.mkForce "code";
      GIT_EDITOR = "code --wait";
      BROWSER = "firefox";

      # Development paths
      GOPATH = "$HOME/go";
      GOBIN = "$HOME/go/bin";
      CARGO_HOME = "$HOME/.cargo";

      # Node.js configuration
      NPM_CONFIG_PREFIX = "$HOME/.npm-global";

      # Python configuration
      PYTHONDONTWRITEBYTECODE = "1";
      PYTHONUNBUFFERED = "1";

      # Docker configuration
      DOCKER_BUILDKIT = "1";
      COMPOSE_DOCKER_CLI_BUILD = "1";

      # Performance
      MAKEFLAGS = "-j$(nproc)";
    };
  };

  # Programs configuration
  programs = {
    # Enhanced development shell configuration
    bash.shellAliases = {
      # Development workflow
      dev = "cd ~/Development";
      projects = "cd ~/Projects";

      # Git workflow shortcuts
      gaa = "git add .";
      gcm = "git commit -m";
      gcam = "git commit -am";
      gco = "git checkout";
      gcb = "git checkout -b";
      gbd = "git branch -d";
      gm = "git merge";
      gr = "git rebase";
      gf = "git fetch";
      gpl = "git pull";
      gps = "git push";
      gst = "git stash";
      gsp = "git stash pop";
      glog = "git log --oneline --graph --decorate";

      # Docker shortcuts
      dcu = "docker-compose up";
      dcd = "docker-compose down";
      dcr = "docker-compose restart";
      dcl = "docker-compose logs -f";
      dce = "docker-compose exec";

      # Kubernetes shortcuts
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      kgd = "kubectl get deployments";
      kdp = "kubectl describe pod";
      kds = "kubectl describe service";
      kdd = "kubectl describe deployment";

      # Python development
      py = "python3";
      pip = "pip3";
      venv = "python3 -m venv";
      activate = "source venv/bin/activate";

      # Node.js development
      ni = "npm install";
      ns = "npm start";
      nt = "npm test";
      nb = "npm run build";

      # Rust development
      cc = "cargo check";
      cb = "cargo build";
      cr = "cargo run";
      ct = "cargo test";

      # Go development
      gob = "go build";
      gor = "go run";
      got = "go test";
      gom = "go mod";

      # File searching and processing
      rg = "ripgrep";
      fd = "fd --type f";

      # JSON processing
      jqp = "jq '.' | less"; # Pretty print JSON

      # Quick servers
      serve-py = "python3 -m http.server";
      serve-node = "npx http-server";

      # System monitoring for development
      ports = "netstat -tuln";
      listen = "lsof -i -P -n | grep LISTEN";

      # Database shortcuts
      pg-start = "pg_ctl -D /usr/local/var/postgres start";
      pg-stop = "pg_ctl -D /usr/local/var/postgres stop";
    };

    zsh.shellAliases = {
      # Inherit development aliases
      dev = "cd ~/Development";
      projects = "cd ~/Projects";
      gaa = "git add .";
      gcm = "git commit -m";
      gcam = "git commit -am";
      gco = "git checkout";
      gcb = "git checkout -b";
      dcu = "docker-compose up";
      dcd = "docker-compose down";
      k = "kubectl";
      py = "python3";
      ni = "npm install";
      cc = "cargo check";
      rg = "ripgrep";
      serve-py = "python3 -m http.server";
    };

    # Development-focused Git configuration
    git = {
      extraConfig = {
        # Enhanced development workflow
        push.default = "current";
        pull.ff = "only";
        merge = {
          ff = false;
          conflictstyle = "diff3";
          ours.driver = true;
        };

        # Better conflict resolution
        rerere.enabled = true;

        # Improved logging
        log.date = "relative";

        # Development-specific aliases
        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          visual = "!gitk";
          tree = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          cleanup = "!git branch --merged | grep -v '\\\\*\\\\|master\\\\|main' | xargs -n 1 git branch -d";
        };

        # Diff and merge configuration
        diff.algorithm = "patience";

        # Submodule handling
        submodule.recurse = true;
      };

      # Git hooks for development workflow (add specific hooks in host configs if needed)
      # hooks = {
      #   pre-commit = lib.mkDefault ./pre-commit-hook.sh; # Enable if pre-commit is used
      # };
    };
  };

  # Development-specific XDG directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    # Custom development directories
    extraConfig = {
      XDG_PROJECTS_DIR = "$HOME/Projects";
      XDG_DEVELOPMENT_DIR = "$HOME/Development";
    };
  };
}
