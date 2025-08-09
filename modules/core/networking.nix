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

    # Firewall configuration moved to modules/core/security.nix to avoid duplication
  };

  # mDNS/DNS-SD support (keep mkDefault - not everyone wants mDNS)
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;
  };
}
