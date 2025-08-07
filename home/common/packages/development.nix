# Development Packages
# Tools for software development and programming
{ pkgs, lib, ... }:

{
  home.packages = with pkgs; lib.mkDefault [
    # Version Control
    git-lfs # Git Large File Storage
    gh # GitHub CLI

    # Build Tools
    gnumake # Make build system
    cmake # Cross-platform build system

    # Language Support
    nodejs_22 # Node.js runtime
    python3 # Python interpreter

    # Development Utilities
    docker-compose # Container orchestration

    # Code Quality
    shellcheck # Shell script linter

    # Documentation
    pandoc # Document converter

    # Database Tools
    sqlite # SQLite database

    # Network Development
    httpie # Human-friendly HTTP client

    # Container Tools (if not using system docker)
    dive # Docker image explorer

    # Performance Analysis
    hyperfine # Benchmarking tool

    # Text Processing for Development
    ripgrep # Fast text search
    fd # Fast file finder
    bat # Better cat with syntax highlighting

    # JSON/YAML tools
    fx # JSON viewer
    yq-go # YAML processor
  ];
}
