{ config, lib, pkgs, ... }:

{
  # User configuration
  users = {
    # Use mutable users (allow passwd, etc.)
    mutableUsers = lib.mkDefault true;
    
    # Default shell
    defaultUserShell = pkgs.bash;
    
    # System groups
    groups = {
      # Additional groups can be defined here
    };
    
    # System users
    users = {
      root = {
        # Disable root login by default
        hashedPassword = "!";
      };
    };
  };
  
  # Shell configuration
  programs = {
    # Enable bash completion (updated option name)
    bash = {
      completion.enable = true;
      
      # Global bashrc additions
      shellInit = ''
        # Custom prompt
        export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]$ "
        
        # Useful aliases
        alias ll="ls -alF"
        alias la="ls -A"  
        alias l="ls -CF"
        alias grep="grep --color=auto"
        alias ..="cd .."
        alias ...="cd ../.."
      '';
    };
    
    # Enable git globally
    git.enable = true;
    
    # Enable vim as default editor
    vim = {
      enable = true;
      defaultEditor = true;
    };
  };
}