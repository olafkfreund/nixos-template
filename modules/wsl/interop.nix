# Windows Interoperability for WSL2
# Provides seamless integration with Windows applications and file system

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.wsl.interop;
in

{
  options.modules.wsl.interop = {
    enable = mkEnableOption "WSL Windows interoperability features";

    windowsPath = mkOption {
      type = types.bool;
      default = true;
      description = "Include Windows PATH in WSL PATH";
    };

    windowsApps = mkOption {
      type = types.bool;
      default = true;
      description = "Enable launching Windows applications from WSL";
    };

    clipboard = mkOption {
      type = types.bool;
      default = true;
      description = "Enable shared clipboard between WSL and Windows";
    };

    fileAssociations = mkOption {
      type = types.bool;
      default = true;
      description = "Enable file associations to open Windows applications";
    };
  };

  config = mkIf cfg.enable {
    # Windows PATH integration
    environment.sessionVariables = mkIf cfg.windowsPath {
      PATH = "$PATH:/mnt/c/Windows/System32:/mnt/c/Windows:/mnt/c/Windows/System32/WindowsPowerShell/v1.0";
    };

    # Shell aliases for common Windows applications
    environment.shellAliases = mkIf cfg.windowsApps {
      # Windows applications
      explorer = "explorer.exe";
      notepad = "notepad.exe";
      code = "code.exe";
      pwsh = "pwsh.exe";
      cmd = "cmd.exe";

      # Development tools
      "visual-studio" = "/mnt/c/Program\\ Files/Microsoft\\ Visual\\ Studio/*/Community/Common7/IDE/devenv.exe";

      # Windows utilities
      ipconfig = "ipconfig.exe";
      tasklist = "tasklist.exe";
      taskkill = "taskkill.exe";
    };

    # System packages for Windows integration
    environment.systemPackages = with pkgs; mkMerge [
      # Clipboard integration tools
      (mkIf cfg.clipboard [
        xclip # For X11 clipboard access
        wl-clipboard # For Wayland clipboard access
      ])

      # Windows integration script wrappers
      [
        (pkgs.writeShellScriptBin "open-in-windows" ''
          exec /etc/wsl-scripts/open-in-windows.sh "$@"
        '')
        (pkgs.writeShellScriptBin "edit-in-windows" ''
          exec /etc/wsl-scripts/edit-in-windows.sh "$@"
        '')
      ]
    ];

    # Environment variables for GUI applications
    environment.variables = {
      # Display configuration for GUI apps
      DISPLAY = ":0.0";
      LIBGL_ALWAYS_INDIRECT = "1";

      # WSL environment variables
      WSLENV = "DISPLAY/u:LIBGL_ALWAYS_INDIRECT/u";

      # Windows browser integration
      BROWSER = "/mnt/c/Program Files/Mozilla Firefox/firefox.exe";
    };

    # Windows integration files and scripts
    environment.etc = mkMerge [
      # File associations for opening Windows applications
      (mkIf cfg.fileAssociations {
        "wsl-interop/file-associations.sh" = {
          text = ''
            #!/bin/bash
            # File association handlers for WSL
            
            case "$1" in
              *.docx|*.doc)
                /mnt/c/Program\ Files/Microsoft\ Office/root/Office16/WINWORD.EXE "$@"
                ;;
              *.xlsx|*.xls)
                /mnt/c/Program\ Files/Microsoft\ Office/root/Office16/EXCEL.EXE "$@"
                ;;
              *.pptx|*.ppt)
                /mnt/c/Program\ Files/Microsoft\ Office/root/Office16/POWERPNT.EXE "$@"
                ;;
              *.pdf)
                explorer.exe "$@"
                ;;
              *)
                echo "No Windows association for file type: $1"
                ;;
            esac
          '';
          mode = "0755";
        };
      })

      # Windows integration scripts
      {
        "wsl-scripts/open-in-windows.sh" = {
          text = ''
            #!/bin/bash
            # Open file or directory in Windows
            
            if [ -z "$1" ]; then
              echo "Usage: $0 <file_or_directory>"
              exit 1
            fi
            
            # Convert WSL path to Windows path
            WINDOWS_PATH=$(wslpath -w "$1")
            explorer.exe "$WINDOWS_PATH"
          '';
          mode = "0755";
        };

        "wsl-scripts/edit-in-windows.sh" = {
          text = ''
            #!/bin/bash
            # Edit file in Windows application
            
            if [ -z "$1" ]; then
              echo "Usage: $0 <file>"
              exit 1
            fi
            
            # Convert WSL path to Windows path
            WINDOWS_PATH=$(wslpath -w "$1")
            
            # Detect file type and open appropriate editor
            case "$1" in
              *.md|*.txt|*.log)
                notepad.exe "$WINDOWS_PATH"
                ;;
              *.js|*.ts|*.json|*.py|*.nix|*.sh)
                code.exe "$WINDOWS_PATH"
                ;;
              *)
                code.exe "$WINDOWS_PATH"
                ;;
            esac
          '';
          mode = "0755";
        };
      }
    ];

    # Systemd service for clipboard synchronization
    systemd.user.services.wsl-clipboard = mkIf cfg.clipboard {
      description = "WSL Clipboard Synchronization";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 1;
      };
      script = ''
        # Basic clipboard sync service
        while true; do
          # This is a placeholder for more advanced clipboard sync
          sleep 10
        done
      '';
    };

  };
}
