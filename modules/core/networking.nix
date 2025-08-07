{ lib, ... }:

{
  # Networking configuration
  networking = {
    # Use NetworkManager for desktop systems
    networkmanager.enable = lib.mkDefault true;

    # Disable wpa_supplicant when using NetworkManager
    wireless.enable = lib.mkDefault false;

    # IPv6 is enabled by default

    # DNS configuration
    nameservers = lib.mkDefault [
      "1.1.1.1" # Cloudflare
      "8.8.8.8" # Google
    ];

    # Note: localhost mapping is automatic in NixOS

    # Firewall
    firewall = {
      enable = lib.mkDefault true;
      allowPing = lib.mkDefault true;

      # Common ports that might need to be opened per host
      # allowedTCPPorts = [ ];
      # allowedUDPPorts = [ ];
    };

    # Predictable interface names are enabled by default
  };

  # mDNS/DNS-SD support
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };
}
