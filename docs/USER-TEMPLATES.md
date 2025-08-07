# User Templates Guide

This NixOS template includes several pre-configured user templates for different use cases. Each template provides a complete Home
Manager configuration optimized for specific workflows.

## Available User Templates

### Basic User (`user.nix`)

- **Purpose**: Default, general-purpose user configuration
- **Desktop**: GNOME (configurable)
- **Features**: Basic shell setup, essential applications, simple git configuration
- **Best for**: General desktop usage, beginners

### Developer User (`developer.nix`)

- **Purpose**: Software development focused configuration
- **Desktop**: GNOME/KDE recommended
- **Features**: Development tools, enhanced git, IDE integrations, multiple language support
- **Best for**: Software developers, programmers, DevOps engineers

### Gaming User (`gamer.nix`)

- **Purpose**: Gaming and entertainment focused configuration
- **Desktop**: KDE recommended (best gaming integration)
- **Features**: Steam, Lutris, Discord, streaming tools, gaming optimizations
- **Best for**: Gamers, content creators, entertainment

### Minimal User (`minimal.nix`)

- **Purpose**: Lightweight configuration for resource-constrained systems
- **Desktop**: None (terminal-focused)
- **Features**: Essential tools only, minimal resource usage
- **Best for**: Servers, old hardware, embedded systems

### Server Admin (`server.nix`)

- **Purpose**: System administration and server management
- **Desktop**: None (terminal-focused)
- **Features**: Administrative tools, monitoring, networking, security utilities
- **Best for**: System administrators, DevOps, server management

## Quick Start

### 1. Choose a Template

```bash
# List available user templates
just list-users

# Show template details
just show-user developer
```

### 2. Initialize User Configuration

```bash
# Initialize a new user configuration from template
just init-user myhost developer

# Or copy manually
cp home/users/developer.nix hosts/myhost/home.nix
```

### 3. Customize Configuration

Edit the created home.nix file to customize:

- Username and email
- Desktop environment preference
- Application selection
- Personal settings

### 4. Apply Configuration

```bash
# Test the configuration
just test myhost

# Apply the configuration
just switch myhost
```

## Template Details

### Basic User Template

**Applications included:**

- Firefox (web browser)
- Git (version control)
- Basic command line tools
- File management utilities

**Configuration highlights:**

- Simple bash prompt
- Basic aliases
- Essential XDG directories
- GNOME desktop integration

**Customization points:**

- Desktop environment (import different profile)
- Git user information
- Shell aliases and prompt
- Application selection

### Developer Template

**Applications included:**

- VSCode (IDE)
- Development languages (Node.js, Python, Rust, Go, C/C++)
- Git with advanced configuration
- Docker tools (optional)
- Database tools (optional)
- Cloud tools (optional)

**Configuration highlights:**

- Enhanced shell with git branch display
- Development-focused aliases
- Multiple language support
- Advanced git configuration with GPG signing
- Project directory structure

**Customization points:**

- IDE preference (VSCode, JetBrains, etc.)
- Programming languages
- Cloud provider tools
- Container platform (Docker/Podman)
- Git signing configuration

### Gaming Template

**Applications included:**

- Steam (gaming platform)
- Lutris (gaming launcher)
- Discord (communication)
- OBS Studio (streaming)
- Wine and Proton tools
- Emulators (optional)

**Configuration highlights:**

- Gaming-optimized environment variables
- MangoHud configuration
- GameMode integration
- Controller support
- Steam and Proton optimizations

**Customization points:**

- Gaming platforms (Steam, Epic, etc.)
- Emulation systems
- Streaming software
- Input device configuration
- Performance optimizations

### Minimal Template

**Applications included:**

- nano, vim (text editors)
- Essential file utilities
- Basic networking tools
- Minimal system information tools

**Configuration highlights:**

- Lightweight package selection
- Simple bash configuration
- Essential-only XDG directories
- Minimal environment variables

**Customization points:**

- Text editor preference
- Essential applications only
- Shell configuration
- System monitoring level

### Server Admin Template

**Applications included:**

- System monitoring tools (htop, iotop, nethogs)
- Network diagnostics (nmap, tcpdump, mtr)
- Security tools (GPG, OpenSSL)
- Backup tools (borgbackup, rclone)
- Container tools (optional)
- Cloud administration tools (optional)

**Configuration highlights:**

- Advanced SSH configuration
- System information functions
- Service management aliases
- Enhanced logging and history
- Security-focused settings

**Customization points:**

- Monitoring tool selection
- Cloud provider tools
- Container platform
- Backup strategy tools
- Security tool selection

## Customization Guide

### Changing Desktop Environment

Each template imports a desktop profile. To change desktop environments:

```nix
imports = [
  # Change this line to your preferred desktop
  ../profiles/kde.nix        # For KDE Plasma
  # ../profiles/gnome.nix    # For GNOME
  # ../profiles/hyprland.nix # For Hyprland
  # ../profiles/niri.nix     # For Niri
];
```

### Adding Custom Applications

Add applications to the `home.packages` section:

```nix
home.packages = with pkgs; [
  # Existing packages...

  # Add your custom applications
  thunderbird    # Email client
  gimp          # Image editor
  libreoffice   # Office suite
];
```

### Customizing Shell Configuration

Modify the bash configuration:

```nix
programs.bash = {
  enable = true;

  shellAliases = {
    # Add your custom aliases
    myalias = "my command";
  };

  bashrcExtra = ''
    # Add custom bash configuration
    export MY_VARIABLE="value"
  '';
};
```

### Environment Variables

Set custom environment variables:

```nix
home.sessionVariables = {
  # Add your environment variables
  MY_APP_CONFIG = "${config.home.homeDirectory}/.config/myapp";
  CUSTOM_PATH = "/usr/local/custom/bin";
};
```

## Multiple Users

You can configure different users with different templates:

```nix
# In your NixOS configuration
home-manager.users = {
  alice = import ./hosts/desktop/alice-home.nix;
  bob = import ./hosts/desktop/bob-home.nix;
};
```

Where each user file is based on a different template.

## Template Comparison

| Feature            | Basic     | Developer   | Gaming | Minimal     | Server         |
| ------------------ | --------- | ----------- | ------ | ----------- | -------------- |
| **Resource Usage** | Low       | Medium      | High   | Very Low    | Low            |
| **Applications**   | Essential | Development | Gaming | Minimal     | Admin Tools    |
| **Desktop**        | GNOME     | Any         | KDE    | None        | None           |
| **Complexity**     | Simple    | Advanced    | Medium | Very Simple | Advanced       |
| **Use Case**       | General   | Coding      | Gaming | Embedded    | Administration |

## Creating Custom Templates

To create your own user template:

1. **Copy existing template:**

   ```bash
   cp home/users/user.nix home/users/mytemplate.nix
   ```

1. **Customize the configuration:**
   - Modify applications in `home.packages`
   - Adjust shell configuration
   - Add specific environment variables
   - Configure programs as needed

1. **Test the template:**

   ```bash
   just init-user testhost mytemplate
   just test testhost
   ```

1. **Document your template:**
   - Add comments explaining the purpose
   - Document customization points
   - Include usage examples

## Troubleshooting

### Common Issues

**Template not found:**

```bash
ERROR: Template 'mytemplate' not found
```

- Check template exists in `home/users/`
- Verify filename matches template name

**Configuration conflicts:**

```bash
ERROR: The option 'programs.git.userName' is defined multiple times
```

- Remove duplicate configurations
- Check imported profiles for conflicts

**Desktop environment conflicts:**

```bash
ERROR: Multiple desktop environments enabled
```

- Ensure only one desktop profile is imported
- Check system configuration matches user config

### Getting Help

1. **Check template documentation** in comments
1. **Validate configuration:** `just validate`
1. **Test before switching:** `just test hostname`
1. **Check Home Manager documentation**
1. **Review NixOS options search**

## Best Practices

### Template Selection

1. **Start simple**: Begin with basic template, add features as needed
1. **Match use case**: Choose template that fits your primary usage
1. **Consider resources**: Ensure system can handle template requirements
1. **Plan for growth**: Choose template that can grow with your needs

### Customization

1. **Document changes**: Add comments for custom modifications
1. **Test thoroughly**: Always test before applying to main system
1. **Backup configurations**: Keep working configurations safe
1. **Version control**: Use git to track configuration changes

### Maintenance

1. **Regular updates**: Keep templates updated with system
1. **Clean unused**: Remove packages and configurations not needed
1. **Monitor resources**: Check system performance regularly
1. **Security updates**: Keep security-sensitive applications current

## Advanced Usage

### Template Inheritance

Create templates that inherit from others:

```nix
# custom-developer.nix
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ./developer.nix  # Inherit from developer template
  ];

  # Override or extend configurations
  home.packages = with pkgs; [
    # Additional packages beyond developer template
    postman
    insomnia
  ];

  # Override git configuration
  programs.git.userEmail = lib.mkForce "custom@example.com";
}
```

### Conditional Configurations

Use conditions to customize based on system:

```nix
{ config, lib, pkgs, ... }:

{
  # Conditional gaming applications
  home.packages = with pkgs; [
    # Always include basics
    firefox
    git
  ] ++ lib.optionals (config.hardware.nvidia.enable) [
    # Only if NVIDIA GPU present
    cuda-tools
    nvidia-settings
  ] ++ lib.optionals (system == "x86_64-linux") [
    # Only on x86_64 systems
    steam
  ];
}
```

### Modular Configurations

Split large templates into modules:

```nix
# home/modules/development/languages.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs_22
    python3
    rustc
    go
  ];
}

# Then import in template
imports = [
  ../modules/development/languages.nix
];
```

## Contributing Templates

To contribute a new template:

1. **Create template** following existing patterns
1. **Test thoroughly** on multiple systems
1. **Document features** and use cases
1. **Add to template list** in this documentation
1. **Submit for review**

Template naming convention: `purpose.nix` (e.g., `scientist.nix`, `artist.nix`)
