# Preconfigured installer with template configurations
# This installer includes this template's configurations ready to install

{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ./base.nix
  ];

  # ISO metadata
  image.fileName = "nixos-preconfigured-installer.iso";
  isoImage = {
    volumeID = "NIXOS_PRECONFIG";
  };

  # Copy this entire configuration template to the ISO
  environment.etc."nixos-template" = {
    source = ../../..;  # Root of this repository (from modules/installer/)
    mode = "0755";
  };

  # Enhanced packages for working with the template
  environment.systemPackages = with pkgs; [
    # All base packages plus:
    
    # Development tools
    just
    nixpkgs-fmt
    statix
    deadnix
    
    # Advanced editors
    neovim
    
    # Git for cloning/updating
    git
    
    # JSON/YAML tools
    jq
    yq
    
    # Archive tools
    unzip
    zip
    
    # Advanced terminal tools
    fzf
    ripgrep
    fd
    bat
    eza
  ];

  # Install script that uses the preconfigured templates
  environment.etc."installer/preconfigured-install.sh" = {
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      
      # Colors
      RED='\033[0;31m'
      GREEN='\033[0;32m'
      YELLOW='\033[1;33m'
      BLUE='\033[0;34m'
      NC='\033[0m'
      
      log_info() { echo -e "''${BLUE}[INFO]''${NC} $1"; }
      log_success() { echo -e "''${GREEN}[SUCCESS]''${NC} $1"; }
      log_warning() { echo -e "''${YELLOW}[WARNING]''${NC} $1"; }
      log_error() { echo -e "''${RED}[ERROR]''${NC} $1"; }
      
      cat << 'EOF'
      ╔══════════════════════════════════════════════════════════════╗
      ║                NixOS Preconfigured Installer                 ║
      ║                                                              ║
      ║     This installer includes ready-to-use configurations!     ║
      ╚══════════════════════════════════════════════════════════════╝
      EOF
      
      echo
      log_info "This ISO includes preconfigured NixOS templates:"
      echo
      echo "Available configurations:"
      ls -la /etc/nixos-template/hosts/ | grep -E "^d" | awk '{print "  - " $9}' | grep -v "^\.$\|^\.\.$"
      echo
      
      echo "Installation options:"
      echo "1. Quick install with template (recommended)"
      echo "2. Custom installation" 
      echo "3. Show available templates"
      echo "4. Exit to shell"
      echo
      
      while true; do
        read -p "Choose option [1-4]: " choice
        case $choice in
          1)
            quick_install
            break
            ;;
          2)
            custom_install  
            break
            ;;
          3)
            show_templates
            ;;
          4)
            log_info "Exiting to shell. Templates available at /etc/nixos-template/"
            exit 0
            ;;
          *)
            log_warning "Invalid option. Please choose 1-4."
            ;;
        esac
      done
      
      quick_install() {
        log_info "Quick installation with template"
        echo
        
        # Show available templates
        echo "Available templates:"
        local templates=($(ls /etc/nixos-template/hosts/ | grep -v common.nix))
        for i in "''${!templates[@]}"; do
          echo "  $((i+1)). ''${templates[$i]}"
        done
        echo
        
        read -p "Select template [1-''${#templates[@]}]: " template_choice
        if [[ $template_choice -ge 1 && $template_choice -le ''${#templates[@]} ]]; then
          local selected_template="''${templates[$((template_choice-1))]}"
          log_info "Selected template: $selected_template"
          
          # Check if /mnt is mounted
          if ! mountpoint -q /mnt; then
            log_error "/mnt is not mounted. Please partition and mount your disk first."
            echo
            echo "Quick partition guide:"
            echo "  fdisk /dev/sdX"
            echo "  mkfs.ext4 -L nixos /dev/sdX1"
            echo "  mount /dev/disk/by-label/nixos /mnt"
            echo
            exit 1
          fi
          
          # Copy template to /mnt/etc/nixos
          log_info "Setting up NixOS configuration..."
          mkdir -p /mnt/etc/nixos
          
          # Copy the selected template
          cp -r "/etc/nixos-template/hosts/$selected_template/"* /mnt/etc/nixos/
          
          # Copy supporting files
          cp -r /etc/nixos-template/modules /mnt/etc/nixos/
          cp -r /etc/nixos-template/lib /mnt/etc/nixos/
          cp /etc/nixos-template/flake.nix /mnt/etc/nixos/
          cp /etc/nixos-template/flake.lock /mnt/etc/nixos/
          
          # Generate hardware config
          log_info "Generating hardware configuration..."
          nixos-generate-config --root /mnt --no-filesystems
          
          # Backup generated config and use template
          mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix.generated
          
          log_success "Configuration ready!"
          echo
          echo "Next steps:"
          echo "1. Review/edit /mnt/etc/nixos/configuration.nix"
          echo "2. Update hardware-configuration.nix if needed"  
          echo "3. Run: nixos-install"
          echo
          
          read -p "Install now? [y/N]: " install_now
          if [[ $install_now =~ ^[Yy]$ ]]; then
            log_info "Starting NixOS installation..."
            nixos-install
          fi
        else
          log_error "Invalid template selection"
        fi
      }
      
      custom_install() {
        log_info "Custom installation"
        echo "You can manually copy configurations from /etc/nixos-template/"
        echo "Standard installation process applies."
        echo
        echo "Template structure:"
        tree /etc/nixos-template/ -L 2 -d || ls -la /etc/nixos-template/
      }
      
      show_templates() {
        echo
        log_info "Available templates in this installer:"
        echo
        
        for template_dir in /etc/nixos-template/hosts/*/; do
          template_name=$(basename "$template_dir")
          [[ "$template_name" == "common.nix" ]] && continue
          
          echo "📁 $template_name"
          if [[ -f "$template_dir/configuration.nix" ]]; then
            # Try to extract description from config
            local desc=""
            if grep -q "desktop" "$template_dir/configuration.nix"; then
              desc="Desktop environment configuration"
            elif grep -q "server" "$template_dir/configuration.nix"; then  
              desc="Server configuration"
            elif grep -q "vm" "$template_dir/configuration.nix"; then
              desc="Virtual machine configuration"
            else
              desc="NixOS configuration template"
            fi
            echo "   $desc"
          fi
          echo
        done
        
        echo "To inspect a template:"
        echo "  cat /etc/nixos-template/hosts/TEMPLATE_NAME/configuration.nix"
        echo
      }
      
      # Run main function
      main() {
        # Check if running as root
        if [[ $EUID -ne 0 ]]; then
          log_error "This installer must be run as root"
          exit 1
        fi
        
        # Start installation process
        show_templates
      }
      
      main "$@"
    '';
    mode = "0755";
  };

  # Auto-start installer on tty1
  systemd.services."installer-start" = {
    description = "NixOS Preconfigured Installer";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.systemd}/bin/systemctl start getty@tty1.service";
    };
  };

  # Custom getty with installer
  systemd.services."getty@tty1".serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.util-linux}/sbin/agetty --autologin root --login-program ${pkgs.shadow}/bin/login tty1 linux"
  ];

  # Show installer info on root login
  programs.bash.interactiveShellInit = ''
    if [ "$XDG_SESSION_TYPE" = "tty" ] && [ "$(tty)" = "/dev/tty1" ] && [ -z "$INSTALLER_STARTED" ]; then
      export INSTALLER_STARTED=1
      /etc/installer/preconfigured-install.sh
    fi
  '';

  # Enhanced shell environment
  programs.bash.shellAliases = {
    # Template navigation
    "templates" = "ls -la /etc/nixos-template/hosts/";
    "show-template" = "cat /etc/nixos-template/hosts/";
    
    # Installation helpers  
    "installer" = "/etc/installer/preconfigured-install.sh";
    "quick-install" = "/etc/installer/preconfigured-install.sh";
    
    # Common installation commands
    "mount-boot" = "mkdir -p /mnt/boot && mount /dev/disk/by-label/BOOT /mnt/boot";
    "mount-root" = "mount /dev/disk/by-label/nixos /mnt";
  };
}