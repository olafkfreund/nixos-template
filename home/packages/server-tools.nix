# Server administration and monitoring tools
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # System administration
    systemctl-tui
    btop
    iotop
    nethogs

    # Network utilities
    tcpdump
    wireshark-cli
    iftop
    bandwhich

    # Log analysis
    lnav
    multitail

    # Backup and sync
    borgbackup
    duplicity

    # Database tools
    postgresql
    redis
    sqlite

    # Monitoring
    prometheus-node-exporter
    grafana-agent
  ];
}