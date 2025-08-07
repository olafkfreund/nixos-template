# Essential Packages
# Core command-line tools that every user should have
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; lib.mkDefault [
    # File and text processing
    file              # File type identification
    tree              # Directory tree visualization
    less              # Pager
    which             # Command location
    
    # Archive and compression
    unzip             # ZIP extraction
    zip               # ZIP creation
    gzip              # GZIP compression
    tar               # TAR archives
    
    # Network tools
    curl              # HTTP client
    wget              # File downloader
    
    # System monitoring
    htop              # Process monitor
    iotop             # I/O monitor
    
    # Text editors
    nano              # Simple editor
    vim               # Advanced editor
    
    # Development basics
    git               # Version control
    
    # NixOS utilities
    nh                # NixOS helper - better nixos-rebuild interface
    
    # Utilities
    jq                # JSON processor
    yq-go             # YAML/XML processor
  ];
}