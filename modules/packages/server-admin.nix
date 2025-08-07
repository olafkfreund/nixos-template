# Server administration packages
# Monitoring, networking, and system administration tools
{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # System monitoring
    htop
    btop
    iotop
    nethogs
    bandwhich

    # Network utilities
    tcpdump
    wireshark-cli
    iftop
    iproute2 # provides ss command
    net-tools # provides netstat

    # Text editors
    vim
    nano

    # Terminal multiplexers
    tmux
    screen

    # File transfer and sync
    rsync
    openssh # provides scp

    # System analysis
    strace
    ltrace
    lsof

    # Log management  
    # Note: journalctl is part of systemd, always available
    logrotate
  ];
}
