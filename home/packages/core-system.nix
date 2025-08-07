# Core system packages used across most configurations
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Essential file utilities
    file
    which
    tree
    unzip
    zip

    # Network utilities
    curl
    wget
    dig
    traceroute

    # Text editors
    nano
    vim

    # Version control
    git

    # System monitoring
    htop

    # Hardware utilities
    pciutils
    usbutils
    lshw

    # Network analysis
    nmap
  ];
}
