{ lib, ... }:

{
  # Networking configuration
  networking = {
    # NetworkManager for desktop systems (keep mkDefault - some may want systemd-networkd)
    networkmanager.enable = lib.mkDefault true;

    # wpa_supplicant conflicts with NetworkManager (automatic)
    wireless.enable = false;

    # Fast DNS servers (opinionated choice for template)
    nameservers = [
      "1.1.1.1" # Cloudflare
      "8.8.8.8" # Google  
    ];

    # Basic firewall (keep mkDefault - users may want custom firewall)
    firewall = {
      enable = lib.mkDefault true;
      allowPing = true;  # Generally safe default
    };
  };

  # mDNS/DNS-SD support (keep mkDefault - not everyone wants mDNS)
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };
}
