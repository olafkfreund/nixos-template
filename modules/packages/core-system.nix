# Core system packages shared across configurations
# Essential tools that should be available on most NixOS systems
{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Essential command-line tools
    wget
    curl
    git
    vim
    nano
    htop
    tree
    unzip
    zip
    rsync

    # System utilities
    pciutils
    usbutils
    psmisc
    lshw
    lm_sensors
    smartmontools

    # Network utilities
    dig
    iputils  # ping, traceroute, etc.
    nmap
    tcpdump

    # File management
    file
    which
  ];
}