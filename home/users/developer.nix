{ config, lib, pkgs, inputs, outputs, ... }:

{
  # Developer-focused Home Manager configuration
  
  # Import desktop profile (prefer development-friendly environments)
  imports = [
    # Recommended for development
    ../profiles/gnome.nix
    # ../profiles/kde.nix
    # ../profiles/hyprland.nix  # Popular with developers
    # ../profiles/niri.nix
  ];
  
  # User information
  home = {
    username = "developer";
    homeDirectory = "/home/developer";
    stateVersion = "25.05";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Enhanced Git configuration for development
  programs.git = {
    enable = true;
    userName = "Developer Name";
    userEmail = "developer@example.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "code";
      merge.tool = "code";
      diff.tool = "code";
      
      # Better diff and merge
      diff.algorithm = "patience";
      merge.conflictstyle = "diff3";
      
      # Signing commits (uncomment and configure)
      # commit.gpgsign = true;
      # user.signingkey = "YOUR_GPG_KEY_ID";
    };
    
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --oneline --graph --decorate --all";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
    };
  };

  # Advanced shell configuration for development
  programs.bash = {
    enable = true;
    
    shellAliases = {
      # Enhanced listing
      ll = "eza -l --git";
      la = "eza -la --git";
      tree = "eza --tree --git-ignore";
      
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      
      # NixOS development
      rebuild = "sudo nixos-rebuild switch --flake .";
      rebuild-test = "sudo nixos-rebuild test --flake .";
      update = "nix flake update";
      develop = "nix develop";
      
      # Development shortcuts
      code = "code .";
      serve = "python3 -m http.server 8000";
      ports = "ss -tuln";
      
      # Docker shortcuts (if docker is enabled)
      dps = "docker ps";
      di = "docker images";
      dex = "docker exec -it";
      
      # Git shortcuts
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline -10";
    };
    
    bashrcExtra = ''
      # Development-focused prompt with git info
      parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
      }
      export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;31m\]\$(parse_git_branch)\[\033[00m\]\$ "
      
      # History settings optimized for development
      export HISTSIZE=50000
      export HISTFILESIZE=100000
      export HISTCONTROL=ignoredups:erasedups
      shopt -s histappend
      
      # Development environment variables
      export EDITOR="code"
      export VISUAL="code"
      
      # Node.js settings
      export NODE_OPTIONS="--max-old-space-size=8192"
      
      # Python settings
      export PYTHONDONTWRITEBYTECODE=1
      
      # Go settings
      export GOPATH="$HOME/go"
      export PATH="$PATH:$GOPATH/bin"
      
      # Rust settings
      export PATH="$PATH:$HOME/.cargo/bin"
    '';
    
    historyControl = [ "ignoredups" "erasedups" ];
    historySize = 50000;
    historyFileSize = 100000;
  };

  # Development-focused programs
  programs = {
    # Enhanced command line tools
    eza = {
      enable = true;
      aliases = {
        ls = "eza --git";
        ll = "eza -l --git";
        la = "eza -la --git";
        tree = "eza --tree --git-ignore";
      };
    };
    
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
      };
    };
    
    fd.enable = true;
    ripgrep.enable = true;
    
    # System monitoring
    htop.enable = true;
    btop.enable = true;
    
    # Directory navigation
    zoxide.enable = true;
    
    # Fuzzy finder for development
    fzf = {
      enable = true;
      defaultCommand = "fd --type f";
      defaultOptions = [ "--height 40%" "--border" ];
    };
    
    # Modern ls alternative
    lsd = {
      enable = true;
      settings = {
        date = "relative";
        ignore-globs = [
          ".git"
          ".hg"
        ];
      };
    };
    
    # SSH with development-friendly settings
    ssh = {
      enable = true;
      
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          # identityFile = "~/.ssh/id_ed25519";
        };
        
        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
          # identityFile = "~/.ssh/id_ed25519";
        };
        
        "dev-server" = {
          hostname = "dev.example.com";
          user = "developer";
          port = 22;
          # identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
    
    # GPG for signing commits
    gpg = {
      enable = true;
    };
  };

  # Development applications and tools
  home.packages = with pkgs; [
    # IDEs and Editors
    vscode
    # jetbrains.idea-community
    # jetbrains.pycharm-community
    
    # Version Control
    git
    git-lfs
    gitui              # Terminal git UI
    lazygit            # Another git TUI
    delta              # Better git diff
    
    # Development Tools
    curl
    wget
    jq                 # JSON processor
    yq                 # YAML processor
    httpie             # HTTP client
    postman           # API testing
    
    # Build Tools
    gnumake
    cmake
    pkg-config
    
    # Text Processing
    ripgrep
    fd
    sd                 # Better sed
    choose             # Better cut/awk
    
    # Network Tools
    nmap
    dig
    traceroute
    netcat-gnu
    wireshark
    
    # Database Tools
    # postgresql
    # sqlite
    # mysql80
    
    # Container Tools (uncomment if using containers)
    # docker
    # docker-compose
    # podman
    # dive               # Docker image analyzer
    
    # Cloud Tools
    # awscli2
    # google-cloud-sdk
    # azure-cli
    # terraform
    # ansible
    
    # Language-specific tools
    
    # Node.js/JavaScript
    nodejs_22
    yarn
    npm-check-updates
    
    # Python
    python3
    python3Packages.pip
    python3Packages.pipenv
    python3Packages.poetry
    
    # Rust
    rustc
    cargo
    rust-analyzer
    
    # Go
    go
    gopls              # Go language server
    delve              # Go debugger
    
    # Java
    # openjdk17
    # maven
    # gradle
    
    # C/C++
    gcc
    clang
    gdb
    valgrind
    
    # Web Development
    firefox
    # chromium
    
    # System Tools
    file
    which
    tree
    unzip
    zip
    p7zip
    rsync
    
    # Performance Analysis
    perf-tools
    strace
    ltrace
    lsof
    
    # Documentation
    man-pages
    man-pages-posix
    
    # Misc Development
    shellcheck         # Shell script linter
    shfmt              # Shell script formatter
    yamllint           # YAML linter
    
    # System Information
    neofetch
    lshw
    pciutils
    usbutils
  ];

  # Development-friendly XDG directories
  xdg = {
    enable = true;
    
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };
  };

  # Development environment variables
  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
    BROWSER = "firefox";
    TERMINAL = "gnome-terminal";
    
    # Development paths
    PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
    
    # Language-specific variables
    NODE_OPTIONS = "--max-old-space-size=8192";
    PYTHONDONTWRITEBYTECODE = "1";
    
    # History settings
    HISTCONTROL = "ignoredups:erasedups";
    HISTSIZE = "50000";
    HISTFILESIZE = "100000";
  };

  # Create common development directories
  home.file = {
    "Projects/.keep".text = "";
    "Scripts/.keep".text = "";
    ".config/Code/User/settings.json" = lib.mkIf (builtins.pathExists ./vscode-settings.json) {
      source = ./vscode-settings.json;
    };
  };

  # Services for development
  services = {
    # GPG agent for signing commits
    gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 86400;  # 24 hours
      maxCacheTtl = 86400;
    };
  };
}