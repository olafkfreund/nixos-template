# Nixvim Configuration

This directory contains a comprehensive Neovim configuration built with Nixvim and Home Manager. The configuration provides a modern development environment with LSP support, fuzzy finding, and productivity enhancements.

## Features

### Core Functionality
- **LSP Integration**: Full Language Server Protocol support for multiple languages
- **Fuzzy Finding**: Telescope for finding files, text, and commands
- **Syntax Highlighting**: Tree-sitter for accurate syntax highlighting
- **Completion**: nvim-cmp with multiple sources for intelligent completion
- **Git Integration**: Gitsigns for in-editor Git operations

### Development Environment
- **File Explorer**: nvim-tree for project navigation
- **Status Line**: Lualine with Git and LSP information
- **Buffer Management**: Bufferline for easy buffer switching
- **Terminal Integration**: Toggleterm for embedded terminal
- **Code Formatting**: Automatic formatting on save

### Supported Languages
- **Nix**: Full support with nil LSP and nixpkgs-fmt
- **Rust**: rust-analyzer with automatic formatting
- **Go**: gopls with Go-specific features
- **Python**: pyright with black formatting
- **JavaScript/TypeScript**: tsserver with prettier
- **Bash**: bashls for shell script development
- **YAML/JSON**: Full support with validation
- **Lua**: lua-ls for Neovim configuration

### Modern Features
- **Which-key**: Interactive key binding help
- **Auto-pairs**: Automatic bracket/quote completion
- **Surround**: Easy text object manipulation
- **Comments**: Smart commenting with context awareness
- **Colorizer**: Live color preview in code
- **Markdown Preview**: Live markdown preview in browser

## Quick Start

### Enable in User Configuration

Add to your Home Manager configuration:

```nix
# Import Nixvim configuration
imports = [
  ../editors/nixvim.nix
];
```

### First Launch

1. **Start Nixvim**:
   ```bash
   nvim
   ```

2. **The configuration is ready to use** - all plugins and language servers are pre-configured

3. **Get help**: Press `<Space>` (leader key) to see available commands

### Basic Usage

#### Key Bindings

**Leader Key**: `Space`

**File Operations**:
- `<leader>ff` - Find files (Telescope)
- `<leader>fg` - Live grep (search in files)
- `<leader>fb` - Switch buffers
- `<leader>fr` - Recent files
- `<leader>e` - Toggle file explorer
- `<leader>w` - Save file
- `<leader>q` - Quit
- `<leader>x` - Save and quit

**LSP Operations**:
- `gd` - Go to definition
- `gr` - Find references
- `gi` - Go to implementation
- `K` - Hover documentation
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol
- `<leader>f` - Format code
- `[d` / `]d` - Navigate diagnostics

**Git Operations**:
- `<leader>gg` - LazyGit (floating terminal)
- Git signs show in the gutter automatically

**Terminal**:
- `<C-\>` - Toggle terminal
- `<C-h/j/k/l>` - Navigate between terminal and editor

**Buffer Management**:
- `Tab` - Next buffer
- `Shift+Tab` - Previous buffer
- `<leader>bd` - Delete buffer

**Window Navigation**:
- `<C-h/j/k/l>` - Navigate between splits
- `<C-Arrow>` - Resize windows

#### Modes and Workflow

1. **File Navigation**: Use `<leader>ff` to quickly find files
2. **Text Search**: Use `<leader>fg` to search across your project
3. **Code Navigation**: Use `gd` to jump to definitions, `gr` for references
4. **Editing**: The editor provides intelligent completion as you type
5. **Git Workflow**: Use `<leader>gg` for LazyGit or observe git changes in the gutter

## Customization

### Adding Languages

To add support for a new language:

1. **Add Tree-sitter parser**:
```nix
treesitter = {
  settings = {
    ensure_installed = [
      # existing parsers...
      "your-language"
    ];
  };
};
```

2. **Add LSP server**:
```nix
lsp = {
  servers = {
    # existing servers...
    your-language-server = {
      enable = true;
    };
  };
};
```

3. **Add formatter to system packages**:
```nix
home.packages = with pkgs; [
  # existing packages...
  your-language-formatter
];
```

### Changing Color Scheme

Replace the catppuccin colorscheme:

```nix
# Disable catppuccin
colorschemes.catppuccin.enable = false;

# Enable different colorscheme
colorschemes.gruvbox = {
  enable = true;
  settings = {
    contrast_dark = "medium";
  };
};
```

Available colorschemes:
- `catppuccin` (default)
- `gruvbox`
- `tokyonight`
- `nord`
- `onedark`
- `dracula`

### Custom Key Bindings

Add custom keymaps:

```nix
keymaps = [
  # existing keymaps...
  {
    mode = "n";
    key = "<leader>t";
    action = ":YourCommand<CR>";
    options.desc = "Your custom command";
  }
];
```

### Plugin Configuration

Modify plugin settings:

```nix
plugins = {
  telescope = {
    settings = {
      defaults = {
        # your telescope customizations
        layout_strategy = "horizontal";
      };
    };
  };
};
```

### Adding New Plugins

Add plugins not available in nixvim:

```nix
extraPlugins = with pkgs.vimPlugins; [
  # existing plugins...
  your-plugin-name
];

extraConfigLua = ''
  -- Configure your plugin
  require('your-plugin').setup({
    -- configuration options
  })
'';
```

## Advanced Configuration

### LSP Customization

Customize LSP server settings:

```nix
lsp = {
  servers = {
    rust-analyzer = {
      settings = {
        rust-analyzer = {
          cargo = {
            features = "all";
          };
          checkOnSave = {
            command = "clippy";
          };
        };
      };
    };
  };
};
```

### Completion Customization

Modify completion behavior:

```nix
cmp = {
  settings = {
    experimental = {
      ghost_text = true;  # Show preview text
    };
    window = {
      completion = {
        border = "rounded";
        scrollbar = true;
      };
    };
  };
};
```

### File Explorer Settings

Customize nvim-tree:

```nix
nvim-tree = {
  renderer = {
    group_empty = true;
    highlight_opened_files = "name";
  };
  filters = {
    dotfiles = false;
    custom = [ ".git" "node_modules" ".cache" ];
  };
};
```

### Terminal Configuration

Customize the terminal:

```nix
toggleterm = {
  settings = {
    direction = "float";  # or "horizontal", "vertical", "tab"
    float_opts = {
      border = "double";
      winblend = 3;
    };
  };
};
```

## Language-Specific Features

### Rust Development
- **rust-analyzer**: Intelligent code analysis
- **Cargo integration**: Run tests and build from editor
- **Rustfmt**: Automatic code formatting
- **Clippy**: Linting with Rust's linter

### Python Development
- **Pyright**: Type checking and intelligent completion
- **Black**: Code formatting
- **Import organization**: Automatic import sorting
- **Virtual environment**: Automatic detection

### Go Development
- **gopls**: Official Go language server
- **Gofmt**: Automatic formatting
- **Go modules**: Full support for Go modules
- **Testing**: Integrated test running

### JavaScript/TypeScript
- **tsserver**: Full TypeScript/JavaScript support
- **Prettier**: Code formatting
- **ESLint**: Linting (when available)
- **Node.js**: Full ecosystem support

### Nix Development
- **nil**: Nix language server
- **nixpkgs-fmt**: Automatic formatting
- **Syntax highlighting**: Full Nix syntax support
- **NixOS integration**: Understanding of NixOS modules

## Troubleshooting

### Common Issues

**LSP not working**:
1. Check if language server is installed: `which rust-analyzer`
2. Restart LSP: `:LspRestart`
3. Check LSP status: `:LspInfo`
4. View LSP logs: `:LspLog`

**Treesitter errors**:
1. Update parsers: `:TSUpdate`
2. Check installation: `:TSInstallInfo`
3. Reinstall parser: `:TSInstall language-name`

**Completion not working**:
1. Check if LSP is running: `:LspInfo`
2. Check completion sources: Type something and see if menu appears
3. Check if nvim-cmp is loaded: `:lua print(vim.inspect(require('cmp')))`

**Telescope not finding files**:
1. Check if ripgrep is installed: `which rg`
2. Check if fd is installed: `which fd`
3. Try from project root: `:cd /path/to/project`

### Performance Issues

**Slow startup**:
1. Check plugin count: Too many plugins can slow startup
2. Profile startup: `nvim --startuptime startup.log`
3. Lazy load plugins when possible

**High memory usage**:
1. Check LSP memory usage
2. Disable unused language servers
3. Reduce Treesitter parsers to only needed ones

**Slow completion**:
1. Adjust completion settings:
   ```lua
   require('cmp').setup({
     performance = {
       max_view_entries = 20,
     }
   })
   ```

### Debugging

**Enable verbose logging**:
```vim
:set verbose=9
```

**Check configuration**:
```vim
:checkhealth
:lua print(vim.inspect(vim.lsp.get_active_clients()))
```

**Plugin debugging**:
```vim
:messages
:lua print(vim.inspect(package.loaded))
```

## Integration with NixOS

### System Integration

The configuration integrates with NixOS/Home Manager by:

1. **Declarative packages**: All plugins and tools defined in Nix
2. **Language servers**: Automatically installed and configured
3. **System clipboard**: Works with X11 and Wayland
4. **Desktop integration**: Proper MIME type associations

### Updating Configuration

1. **Edit the configuration**:
   ```bash
   $EDITOR home/editors/nixvim.nix
   ```

2. **Test changes**:
   ```bash
   just test hostname
   ```

3. **Apply changes**:
   ```bash
   just switch hostname
   ```

4. **Restart Neovim** to load new configuration

### Version Management

**Update Neovim version**:
```nix
programs.nixvim = {
  package = pkgs.neovim-unwrapped;  # Always latest
  # or specific version:
  # package = pkgs.neovim-unwrapped.overrideAttrs (old: rec {
  #   version = "0.9.0";
  # });
};
```

**Plugin versions**: Managed automatically with nixpkgs updates.

## Learning Resources

### Neovim/Vim Basics
- [Neovim Documentation](https://neovim.io/doc/)
- [Vim Tutorial](https://github.com/iggredible/Learn-Vim) (built-in: `vimtutor`)
- [Vim Adventures](https://vim-adventures.com/) (interactive learning)

### Plugin Documentation
- [Telescope](https://github.com/nvim-telescope/telescope.nvim)
- [LSP Config](https://github.com/neovim/nvim-lspconfig)
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- [Treesitter](https://github.com/nvim-treesitter/nvim-treesitter)

### Advanced Topics
- [Nixvim Documentation](https://nix-community.github.io/nixvim/)
- [Neovim Lua Guide](https://github.com/nanotee/nvim-lua-guide)
- [LSP Configuration](https://microsoft.github.io/language-server-protocol/)

## Migration from Other Configs

### From regular Neovim
- Configuration is declarative (no init.lua editing)
- Packages managed by Nix
- Similar key bindings and workflow

### From VSCode
- LSP provides similar IDE features
- Telescope replaces Ctrl+P functionality
- Integrated terminal available

### From Vim
- Modern features while maintaining Vim philosophy
- Familiar key bindings with enhancements
- Better defaults out of the box

## Contributing

To contribute improvements to this configuration:

1. **Test thoroughly** on multiple languages and systems
2. **Document changes** in this README
3. **Follow Nixvim conventions** for configuration
4. **Maintain backward compatibility** where possible
5. **Add appropriate comments** to complex configurations

## Customization Examples

### Personal Workflow Optimization

```nix
# Add to keymaps for your specific workflow
keymaps = [
  {
    mode = "n";
    key = "<leader>pp";
    action = ":Telescope projects<CR>";
    options.desc = "Find projects";
  }
  {
    mode = "n";
    key = "<leader>tt";
    action = ":TestNearest<CR>";
    options.desc = "Run nearest test";
  }
];
```

### Language-Specific Enhancements

```nix
# Add to extraConfigLua for specific languages
extraConfigLua = ''
  -- Rust-specific settings
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function()
      vim.opt_local.colorcolumn = "100"
      vim.keymap.set('n', '<leader>rr', ':!cargo run<CR>', { buffer = true })
    end
  })
'';
```