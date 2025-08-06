{ lib, ... }:

{
  # Networking configuration
  networking = {
    # Use NetworkManager for desktop systems
    networkmanager.enable = lib.mkDefault true;

    # Disable wpa_supplicant when using NetworkManager
    wireless.enable = lib.mkDefault false;

    # Enable IPv6 privacy extensions
    enableIPv6 = lib.mkDefault true;

    # DNS configuration
    nameservers = lib.mkDefault [
      "1.1.1.1" # Cloudflare
      "8.8.8.8" # Google
    ];

    # Local hostname resolution
    hosts = {
      "127.0.0.1" = [ "localhost" ];
      "::1" = [ "localhost" ];
    };

    # Firewall
    firewall = {
      enable = lib.mkDefault true;
      allowPing = lib.mkDefault true;

      # Common ports that might need to be opened per host
      # allowedTCPPorts = [ ];
      # allowedUDPPorts = [ ];
    };

    # Disable predictable network interface names (optional)
    usePredictableInterfaceNames = lib.mkDefault true;
  };

  # mDNS/DNS-SD support
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };
}
