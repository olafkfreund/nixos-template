# Home Manager configuration for WSL2
# Optimized for Windows Subsystem for Linux development environment

{ config, lib, pkgs, ... }:

{
  imports = [
    # Minimal imports for testing
  ];

  # User identification (REQUIRED - must be customized per user)
  home = {
    username = "nixos";  # Change to your username
    homeDirectory = "/home/nixos";  # Change to your home directory
    stateVersion = "25.05";
  };

  # User-specific git configuration (REQUIRED)
  programs.git = {
    userName = "Your Name";  # Change to your name
    userEmail = "your.email@example.com";  # Change to your email
  };

  # WSL2-specific shell configuration
  programs.zsh = {
    enable = true;
    
    # WSL2-specific shell aliases
    shellAliases = {
      # Windows integration
      explorer = "explorer.exe";
      notepad = "notepad.exe";
      code = "code.exe";
      pwsh = "powershell.exe";
      
      # WSL2 utilities
      wsl-shutdown = "wsl.exe --shutdown";
      wsl-restart = "wsl.exe --terminate $WSL_DISTRO_NAME && wsl.exe -d $WSL_DISTRO_NAME";
      
      # Development shortcuts
      ll = "ls -la";
      la = "ls -la";
      "cd.." = "cd ..";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline -10";
      gd = "git diff";
      
      # System shortcuts
      cls = "clear";
      h = "history | tail -20";
      
      # WSL2-specific network helpers
      wsl-ip = "ip route show default | awk '{print $3}'";
      host-ip = "cat /etc/resolv.conf | grep nameserver | awk '{print $2}'";
    };

    # WSL2-specific environment variables
    sessionVariables = {
      # Windows integration
      DISPLAY = ":0.0";
      LIBGL_ALWAYS_INDIRECT = "1";
      
      # WSL environment
      WSLENV = "DISPLAY/u:LIBGL_ALWAYS_INDIRECT/u";
      WSL_DISTRO_NAME = "NixOS";
      
      # Development environment
      EDITOR = "vim";
      BROWSER = "/mnt/c/Program Files/Mozilla Firefox/firefox.exe";
      
      # Performance optimizations
      PYTHONUNBUFFERED = "1";
      PYTHONDONTWRITEBYTECODE = "1";
      CARGO_BUILD_JOBS = "$(nproc)";
      MAKEFLAGS = "-j$(nproc)";
    };

    # WSL2-specific shell initialization
    initExtra = ''
      # WSL2 environment setup
      export WSL2_SETUP=1
      
      # Windows PATH integration helper
      add_windows_path() {
        local win_path="$1"
        if [ -d "$win_path" ]; then
          export PATH="$PATH:$win_path"
        fi
      }
      
      # Add common Windows paths
      add_windows_path "/mnt/c/Windows/System32"
      add_windows_path "/mnt/c/Windows"
      add_windows_path "/mnt/c/Program Files/Git/cmd"
      add_windows_path "/mnt/c/Program Files/Microsoft VS Code/bin"
      
      # WSL2 utility functions
      wsl-open() {
        if [ -z "$1" ]; then
          echo "Usage: wsl-open <file_or_directory>"
          return 1
        fi
        local windows_path=$(wslpath -w "$1" 2>/dev/null)
        if [ $? -eq 0 ]; then
          explorer.exe "$windows_path"
        else
          echo "Error: Cannot convert path to Windows format"
          return 1
        fi
      }
      
      wsl-edit() {
        if [ -z "$1" ]; then
          echo "Usage: wsl-edit <file>"
          return 1
        fi
        local windows_path=$(wslpath -w "$1" 2>/dev/null)
        if [ $? -eq 0 ]; then
          code.exe "$windows_path"
        else
          echo "Error: Cannot convert path to Windows format"
          return 1
        fi
      }
      
      # Network utility functions
      wsl-ports() {
        echo "Listening ports in WSL2:"
        netstat -tlnp | grep LISTEN
      }
      
      wsl-network-info() {
        echo "WSL2 Network Information:"
        echo "WSL IP: $(hostname -I | awk '{print $1}')"
        echo "Host IP: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)"
        echo "Default Gateway: $(ip route | grep default | awk '{print $3}')"
      }
      
      # Development shortcuts
      dev-start() {
        echo "Starting development environment..."
        # Add your development server start commands here
        # Example: cd ~/project && npm run dev
      }
      
      dev-stop() {
        echo "Stopping development servers..."
        # Add your development server stop commands here
        pkill -f "node.*dev" 2>/dev/null || true
        pkill -f "python.*manage.py.*runserver" 2>/dev/null || true
      }
      
      # WSL2 system information
      wsl-info() {
        echo "=== WSL2 System Information ==="
        echo "Distro: $WSL_DISTRO_NAME"
        echo "User: $USER"
        echo "Home: $HOME"
        echo "WSL Version: $(wsl.exe --version 2>/dev/null | head -1 || echo 'WSL 2')"
        echo "Kernel: $(uname -r)"
        echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')"
        echo "CPU Cores: $(nproc)"
        echo "Disk Usage:"
        df -h / /mnt/c 2>/dev/null | grep -E "^(/dev|[A-Z]:)"
        echo "Network: $(wsl-network-info | grep 'WSL IP')"
      }
      
      # Welcome message for new sessions
      if [ -z "$WSL_WELCOME_SHOWN" ]; then
        export WSL_WELCOME_SHOWN=1
        echo "Welcome to NixOS on WSL2!"
        echo "Type 'wsl-info' for system information"
        echo "Type 'wsl-open .' to open current directory in Windows Explorer"
        echo "Type 'wsl-edit file.txt' to edit files in VS Code"
      fi
    '';

    # Oh-My-Zsh configuration optimized for WSL2
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";  # Fast, clean theme
      plugins = [
        "git"
        "docker"
        "npm"
        "yarn"
        "pip"
        "python"
        "rust"
        "golang"
        "history"
        "command-not-found"
      ];
    };
  };

  # Starship prompt configuration for WSL2
  programs.starship = {
    enable = true;
    settings = {
      # Faster prompt rendering
      add_newline = false;
      scan_timeout = 10;
      command_timeout = 1000;
      
      # WSL2-specific format
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nodejs"
        "$python"
        "$rust"
        "$golang"
        "$docker_context"
        "$character"
      ];

      # Show hostname for WSL2 identification
      hostname = {
        ssh_only = false;
        format = "[@$hostname](bold blue) ";
        disabled = false;
      };

      # Git optimizations for WSL2
      git_branch = {
        truncation_length = 20;
        truncation_symbol = "...";
      };

      git_status = {
        disabled = false;
        conflicted = "⚡";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        untracked = "?";
        stashed = "$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      # Language versions (useful for development)
      nodejs = {
        format = "via [⬢ $version](bold green) ";
        detect_files = ["package.json" ".nvmrc"];
      };

      python = {
        format = "via [🐍 $version](bold yellow) ";
        detect_files = ["requirements.txt" "pyproject.toml" ".python-version"];
      };

      rust = {
        format = "via [🦀 $version](bold red) ";
        detect_files = ["Cargo.toml"];
      };

      golang = {
        format = "via [🐹 $version](bold cyan) ";
        detect_files = ["go.mod" "go.sum"];
      };
    };
  };

  # Direnv for project-specific environments
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Git configuration optimized for WSL2
  programs.git = {
    enable = true;
    
    # Performance optimizations for WSL2
    extraConfig = {
      # WSL2-specific optimizations
      core = {
        fileMode = false;  # Windows filesystem compatibility
        autocrlf = false;  # Handle line endings properly
        safecrlf = false;
        preloadindex = true;  # Speed up git status
        fscache = true;  # Windows filesystem cache
      };
      
      # Performance improvements
      feature = {
        manyFiles = true;
      };
      
      index = {
        version = 4;  # Faster index format
      };
      
      # WSL2 credential handling
      credential = {
        helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
      };
      
      # Better diff algorithm
      diff = {
        algorithm = "histogram";
      };
      
      # Faster status
      status = {
        showUntrackedFiles = "normal";
      };
      
      # Push configuration
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      
      # Pull configuration
      pull = {
        rebase = true;
      };
    };
  };

  # Vim configuration for WSL2
  programs.vim = {
    enable = true;
    defaultEditor = true;
    
    extraConfig = ''
      " WSL2-specific vim configuration
      set number
      set relativenumber
      set nowrap
      set tabstop=2
      set shiftwidth=2
      set expandtab
      set autoindent
      set smartindent
      
      " Performance optimizations for WSL2
      set lazyredraw
      set ttyfast
      
      " WSL2 clipboard integration
      set clipboard=unnamedplus
      
      " Color scheme
      colorscheme desert
      
      " Status line
      set statusline=%f%m%r%h%w\ [%Y]\ [%{&ff}]\ %=%l,%c%V\ %P
      set laststatus=2
      
      " Search settings
      set hlsearch
      set incsearch
      set ignorecase
      set smartcase
      
      " File handling
      set autoread
      set noswapfile
      set nobackup
      set undodir=~/.vim/undodir
      set undofile
    '';
  };

  # Tmux for session management in WSL2
  programs.tmux = {
    enable = true;
    
    extraConfig = ''
      # WSL2-optimized tmux configuration
      
      # Enable mouse support
      set -g mouse on
      
      # Increase scrollback buffer
      set -g history-limit 10000
      
      # Start windows and panes at 1
      set -g base-index 1
      setw -g pane-base-index 1
      
      # Renumber windows after closing
      set -g renumber-windows on
      
      # WSL2 clipboard integration
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'clip.exe'
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel 'clip.exe'
      
      # Status bar
      set -g status-bg colour234
      set -g status-fg colour137
      set -g status-left '#[fg=colour233,bg=colour241,bold] #S #[fg=colour241,bg=colour235,nobold]'
      set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
      
      # Window status
      setw -g window-status-current-format ' #I#[fg=colour250]:#[fg=colour255]#W#[fg=colour50]#F '
      setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '
      
      # Pane borders
      set -g pane-border-style fg=colour238
      set -g pane-active-border-style fg=colour208
      
      # Key bindings
      bind | split-window -h
      bind - split-window -v
      bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
    '';
  };

  # WSL2-specific packages
  home.packages = with pkgs; [
    # Windows integration tools
    wslu  # WSL utilities
    
    # Development tools
    curl
    wget
    tree
    jq
    yq
    
    # System utilities
    htop
    iotop
    ncdu
    lsof
    
    # Network tools
    netcat
    nmap
    
    # Archive tools
    unzip
    zip
    p7zip
    
    # Development languages and tools
    nodejs
    python3
    rustc
    cargo
    go
    
    # Editors and IDEs
    nano
    
    # Version control
    lazygit
    
    # File management
    ranger
    fzf
    
    # Performance monitoring
    neofetch
    
    # WSL2-specific utilities
    pciutils
    usbutils
  ];

  # XDG directories (important for WSL2)
  xdg = {
    enable = true;
    
    # Custom user directories for WSL2
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      templates = "$HOME/Templates";
      publicShare = "$HOME/Public";
    };
  };

  # Services that work well in WSL2
  services = {
    # SSH agent for development
    ssh-agent = {
      enable = true;
    };
    
    # GPG agent for signing
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
  };

  # Development shell configurations
  home.file = {
    # WSL2 development environment setup script
    ".local/bin/dev-env-setup".text = ''
      #!/bin/bash
      # WSL2 Development Environment Setup
      
      echo "Setting up WSL2 development environment..."
      
      # Create development directories
      mkdir -p ~/Development/{projects,tools,scripts}
      mkdir -p ~/Development/projects/{web,mobile,desktop,scripts}
      
      # Set up symbolic links to Windows directories (optional)
      if [ ! -L ~/WindowsHome ]; then
        ln -s /mnt/c/Users/$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r') ~/WindowsHome 2>/dev/null || true
      fi
      
      # Set up project templates
      mkdir -p ~/.local/share/project-templates
      
      echo "WSL2 development environment setup completed!"
      echo "Development directories created in ~/Development/"
      echo "Windows user directory linked as ~/WindowsHome"
    '';
    
    ".local/bin/dev-env-setup".executable = true;

    # WSL2 system information script
    ".local/bin/system-info".text = ''
      #!/bin/bash
      # WSL2 System Information Script
      
      echo "=== NixOS on WSL2 System Information ==="
      echo
      
      echo "System:"
      echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2- || echo 'NixOS')"
      echo "  Kernel: $(uname -r)"
      echo "  Architecture: $(uname -m)"
      echo
      
      echo "WSL2:"
      echo "  Distro: $WSL_DISTRO_NAME"
      echo "  User: $USER"
      echo "  Home: $HOME"
      echo
      
      echo "Hardware:"
      echo "  CPU Cores: $(nproc)"
      echo "  Memory: $(free -h | grep '^Mem:' | awk '{print $2" total, "$3" used, "$7" available"}')"
      echo
      
      echo "Storage:"
      df -h / 2>/dev/null | tail -1 | awk '{print "  WSL Root: "$2" total, "$3" used, "$4" available ("$5" used)"}'
      df -h /mnt/c 2>/dev/null | tail -1 | awk '{print "  Windows C:: "$2" total, "$3" used, "$4" available ("$5" used)"}'
      echo
      
      echo "Network:"
      echo "  WSL IP: $(hostname -I | awk '{print $1}')"
      echo "  Host IP: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)"
      echo "  Gateway: $(ip route | grep default | awk '{print $3}')"
      echo
      
      echo "Development Tools:"
      command -v node >/dev/null && echo "  Node.js: $(node --version)"
      command -v python3 >/dev/null && echo "  Python: $(python3 --version | awk '{print $2}')"
      command -v rustc >/dev/null && echo "  Rust: $(rustc --version | awk '{print $2}')"
      command -v go >/dev/null && echo "  Go: $(go version | awk '{print $3}')"
      command -v git >/dev/null && echo "  Git: $(git --version | awk '{print $3}')"
    '';
    
    ".local/bin/system-info".executable = true;

    # WSL2 performance monitoring script
    ".local/bin/performance-monitor".text = ''
      #!/bin/bash
      # WSL2 Performance Monitoring
      
      echo "=== WSL2 Performance Monitor ==="
      echo
      
      echo "System Load:"
      uptime
      echo
      
      echo "Memory Usage:"
      free -h
      echo
      
      echo "CPU Usage (top 10 processes):"
      ps aux --sort=-pcpu | head -11
      echo
      
      echo "Disk I/O:"
      iostat 1 1 2>/dev/null | tail -n +4 || echo "iostat not available"
      echo
      
      echo "Network Connections:"
      netstat -tuln | head -10
      echo
      
      echo "WSL2 Specific Info:"
      echo "  Boot Time: $(uptime -s)"
      echo "  Load Average: $(uptime | awk -F'load average:' '{print $2}')"
      
      # Check for common performance issues
      echo
      echo "Performance Tips:"
      echo "1. Use WSL2 filesystem (/home) for better performance with development files"
      echo "2. Keep large files on Windows filesystem (/mnt/c) if needed by Windows apps"
      echo "3. Use 'wsl --shutdown' periodically to free up memory"
      echo "4. Consider adjusting .wslconfig for memory limits"
    '';
    
    ".local/bin/performance-monitor".executable = true;
  };

  # Enable programs that handle dotfile management
  programs.home-manager.enable = true;
}