# Development packages for system-wide installation
# IDE, editors, and development utilities
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Code editors and IDEs
    vscode
    jetbrains.idea-community

    # Development tools
    docker-compose
    postman
    dbeaver-bin

    # Version control
    git
    gh # GitHub CLI

    # System monitoring for development
    btop
    iotop
    nethogs

    # Terminal utilities
    tmux
    screen
    neofetch
  ];
}
