# WSL2 Systemd Optimizations
# Systemd service configurations optimized for WSL2 environment

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.wsl.systemd;
in

{
  options.modules.wsl.systemd = {
    enable = mkEnableOption "WSL2 systemd optimizations";

    bootOptimization = mkOption {
      type = types.bool;
      default = true;
      description = "Enable boot time optimizations for WSL2";
    };

    serviceTimeouts = mkOption {
      type = types.bool;
      default = true;
      description = "Optimize service timeouts for WSL2 environment";
    };

    userServices = mkOption {
      type = types.bool;
      default = true;
      description = "Enable user service optimizations";
    };

    logging = mkOption {
      type = types.submodule {
        options = {
          optimize = mkOption {
            type = types.bool;
            default = true;
            description = "Optimize logging for WSL2";
          };

          maxLogSize = mkOption {
            type = types.str;
            default = "100M";
            description = "Maximum size for journal logs";
          };

          retention = mkOption {
            type = types.str;
            default = "1week";
            description = "Log retention period";
          };
        };
      };
      default = { };
      description = "Logging optimizations";
    };
  };

  config = mkIf cfg.enable {
    # Boot optimizations
    systemd = mkMerge [
      # Core systemd optimizations
      (mkIf cfg.bootOptimization {
        # Disable hardware-related services not applicable in WSL2
        services = {
          # Hardware detection and management
          "systemd-hwdb-update".enable = false;
          "systemd-udev-trigger".enable = false;
          "systemd-udevd".enable = false;

          # Power management (not applicable in WSL2)
          "systemd-logind".enable = mkDefault false;

          # Console services (WSL2 uses Windows terminal)
          "getty@tty1".enable = false;
          "autovt@tty1".enable = false;

          # Disable module loading (WSL2 kernel is managed by Windows)
          "systemd-modules-load".enable = false;
          "kmod-static-nodes".enable = false;
        };

        # Optimize target dependencies
        targets = {
          # Skip hardware targets
          "hardware.target".enable = false;
          "sound.target".enable = false;
        };
      })

      # Service timeout optimizations
      (mkIf cfg.serviceTimeouts {
        extraConfig = ''
          # Faster service timeouts for WSL2
          DefaultTimeoutStartSec=30s
          DefaultTimeoutStopSec=10s
          DefaultDeviceTimeoutSec=10s
          DefaultRestartSec=100ms
          
          # Faster shutdown
          ShutdownWatchdogSec=30s
          RuntimeWatchdogSec=30s
          
          # WSL2-specific optimizations
          DefaultMemoryAccountingUnit=16M
          DefaultTasksAccountingUnit=10000
        '';

        user.extraConfig = mkIf cfg.userServices ''
          # User service optimizations
          DefaultTimeoutStartSec=10s
          DefaultTimeoutStopSec=5s
          DefaultRestartSec=100ms
        '';
      })

      # Logging optimizations
      (mkIf cfg.logging.optimize {
        services.systemd-journald.extraConfig = ''
          # WSL2 journal optimizations
          Storage=persistent
          Compress=yes
          Seal=yes
          
          # Size limits
          SystemMaxUse=${cfg.logging.maxLogSize}
          SystemKeepFree=500M
          RuntimeMaxUse=100M
          RuntimeKeepFree=100M
          
          # Retention
          MaxRetentionSec=${cfg.logging.retention}
          MaxFileSec=1day
          
          # Performance
          SyncIntervalSec=5m
          RateLimitInterval=30s
          RateLimitBurst=10000
          
          # WSL2-specific settings
          ForwardToWall=no
          ForwardToConsole=no
        '';
      })

      # WSL2-specific service configurations
      {
        services = {
          # WSL2 initialization service
          "wsl-init" = {
            description = "WSL2 Environment Initialization";
            wants = [ "network.target" ];
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              TimeoutStartSec = "30s";
            };

            script = ''
              # WSL2 environment setup
              echo "Initializing WSL2 environment..."
            
              # Create necessary directories
              mkdir -p /run/wsl
            
              # Set up WSL-specific environment
              echo "$(date): WSL2 initialization completed" > /run/wsl/init-status
            
              # Log system information
              echo "WSL2 Host: $(cat /proc/sys/kernel/osrelease)" >> /run/wsl/system-info
              echo "Memory: $(free -h | grep '^Mem:' | awk '{print $2}')" >> /run/wsl/system-info
              echo "CPU: $(nproc) cores" >> /run/wsl/system-info
            '';
          };

          # WSL2 cleanup service
          "wsl-cleanup" = {
            description = "WSL2 Environment Cleanup";
            conflicts = [ "shutdown.target" "reboot.target" ];
            before = [ "shutdown.target" "reboot.target" ];

            serviceConfig = {
              Type = "oneshot";
              TimeoutStopSec = "10s";
              RemainAfterExit = true;
            };

            script = ''
              # WSL2 cleanup tasks
              echo "Performing WSL2 cleanup..."
            
              # Clean temporary files
              find /tmp -type f -mtime +1 -delete 2>/dev/null || true
            
              # Update cleanup timestamp
              echo "$(date): WSL2 cleanup completed" > /run/wsl/cleanup-status
            '';
          };

          # User service optimizations
          "user-wsl-setup@" = mkIf cfg.userServices {
            description = "WSL2 User Environment Setup";
            after = [ "user-runtime-dir@%i.service" ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "%i";
              TimeoutStartSec = "10s";
            };

            script = ''
              # User-specific WSL2 setup
              mkdir -p "$HOME/.local/share/wsl"
              mkdir -p "$HOME/.cache/wsl"
            
              # Create user WSL configuration
              cat > "$HOME/.local/share/wsl/config" << 'EOF'
              # WSL2 User Configuration
              export WSL_DISTRO_NAME="NixOS"
              export WSL_USER="$USER"
              export WSL_HOME="$HOME"
              EOF
            
              echo "$(date): User WSL2 setup completed for $USER" > "$HOME/.local/share/wsl/setup-status"
            '';
          };
        };
      }

      # User services for WSL2  
      (mkIf cfg.userServices {
        systemd.user.services = {
          # User WSL environment
          "wsl-user-env" = {
            description = "WSL2 User Environment";
            wantedBy = [ "default.target" ];
            after = [ "graphical-session-pre.target" ];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };

            script = ''
              # Set up user-specific WSL2 environment
              export WSL_USER_ENV_LOADED=1
          
              # Create user directories
              mkdir -p "$HOME/.local/bin"
              mkdir -p "$HOME/.local/share/applications"
          
              # User-specific optimizations
              echo "WSL2 user environment loaded for $USER"
            '';
          };

          # Development server management
          "wsl-dev-services" = {
            description = "WSL2 Development Services Manager";
            wantedBy = [ "default.target" ];

            serviceConfig = {
              Type = "simple";
              Restart = "no";
              RemainAfterExit = true;
            };

            script = ''
              # Development services coordination
              echo "Development services manager started"
          
              # This service can be extended to manage development servers
              # Example: Start/stop development databases, web servers, etc.
          
              # Create a simple status file
              echo "$(date): Development services ready" > "$HOME/.local/share/wsl/dev-services-status"
            '';
          };
        };
      })

      # WSL2 systemd management scripts  
      {
        environment.etc."wsl-scripts/systemd-status.sh" = {
          text = ''
            #!/bin/bash
            # WSL2 Systemd Status and Management
        
            echo "=== WSL2 Systemd Status ==="
            echo
        
            echo "Boot Analysis:"
            systemd-analyze
            echo
        
            echo "Critical Chain:"
            systemd-analyze critical-chain
            echo
        
            echo "Failed Services:"
            systemctl --failed --no-pager
            echo
        
            echo "WSL2-specific Services:"
            systemctl status wsl-init wsl-cleanup --no-pager -l
            echo
        
            echo "User Services:"
            systemctl --user status wsl-user-env --no-pager -l 2>/dev/null || echo "User services not available"
            echo
        
            echo "System Load:"
            systemctl status --no-pager | head -n 5
            echo
        
            echo "Journal Size:"
            journalctl --disk-usage
          '';
          mode = "0755";
        };

        environment.etc."wsl-scripts/systemd-optimize.sh" = {
          text = ''
            #!/bin/bash
            # WSL2 Systemd Optimization Script
        
            echo "=== WSL2 Systemd Optimization ==="
        
            # Analyze boot performance
            echo "Boot Performance Analysis:"
            systemd-analyze blame | head -n 10
            echo
        
            echo "Service Dependencies:"
            systemd-analyze plot > /tmp/systemd-plot.svg 2>/dev/null
            echo "Boot plot saved to /tmp/systemd-plot.svg (view in browser)"
            echo
        
            # Check for common issues
            echo "Checking for common systemd issues..."
        
            # Check for long-running services
            echo "Long-running startup services:"
            systemd-analyze blame | awk '$1 > "10s" {print}' | head -n 5
            echo
        
            # Check for failed services
            FAILED=$(systemctl --failed --no-legend | wc -l)
            if [ "$FAILED" -gt 0 ]; then
              echo "WARNING: $FAILED failed services found"
              systemctl --failed --no-pager
            else
              echo "No failed services found"
            fi
            echo
        
            echo "Optimization recommendations:"
            echo "1. Services taking >10s to start may need optimization"
            echo "2. Consider disabling unused services with 'systemctl disable SERVICE'"
            echo "3. Use 'systemctl mask SERVICE' for services that shouldn't start"
            echo "4. Check 'journalctl -u SERVICE' for service-specific logs"
          '';
          mode = "0755";
        };

        # Add systemd management scripts and tools to PATH
        environment.systemPackages = with pkgs; [
          # Systemd analysis tools
          systemd-analyze
          systemctl-tui

          # WSL2-specific scripts
          (writeShellScriptBin "wsl-systemd-status" ''
            exec /etc/wsl-scripts/systemd-status.sh "$@"
          '')
          (writeShellScriptBin "wsl-systemd-optimize" ''
            exec /etc/wsl-scripts/systemd-optimize.sh "$@"
          '')
        ];

        # Enable systemd in WSL2 (this is typically handled by NixOS-WSL)
        boot.initrd.systemd.enable = true;
        systemd.enableEmergencyMode = false; # Disable emergency mode in WSL2
      }
    ];
  };
}
