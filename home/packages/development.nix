# Development tools and utilities
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Code editors and IDEs
    vscode
    jetbrains.idea-community

    # Development utilities
    docker-compose
    postman
    dbeaver-bin

    # Shell and terminal tools
    jq
    yq
    strace
    lsof

    # Network development tools
    netcat
    socat
    rsync
    openssh

    # Archive and compression
    p7zip
    unrar
  ];
}