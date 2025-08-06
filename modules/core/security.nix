{ config, lib, pkgs, ... }:

{
  # Security configuration
  security = {
    # Enable sudo with wheel group
    sudo = {
      enable = true;
      wheelNeedsPassword = lib.mkDefault true;
    };
    
    # Polkit configuration
    polkit.enable = true;
    
    # AppArmor support
    apparmor.enable = true;
    
    # Restrict ptrace to same user
    allowUserNamespaces = true;
    
    # Audit framework
    audit.enable = true;
    auditd.enable = true;
  };
  
  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowPing = lib.mkDefault true;  # Allow templates to override this setting
  };
  
  # SSH configuration
  services.openssh = {
    enable = lib.mkDefault false;  # Disabled by default, enable per host
    settings = {
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "no";
      X11Forwarding = lib.mkDefault false;
    };
  };
  
  # Fail2ban for SSH protection when enabled
  services.fail2ban = {
    enable = config.services.openssh.enable;
    maxretry = 3;
    bantime = "10m";
  };
}