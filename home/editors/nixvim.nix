{ config, lib, pkgs, ... }:

{
  # Nixvim configuration with modern Neovim setup
  # This configuration provides a comprehensive Neovim setup with:
  # - LSP support for multiple languages
  # - Treesitter for syntax highlighting
  # - Telescope for fuzzy finding
  # - Modern completion with nvim-cmp
  # - Git integration
  # - File management and productivity plugins

  programs.nixvim = {
    enable = true;

    # Use latest Neovim
    package = pkgs.neovim-unwrapped;

    # Enable Vi compatibility mode
    viAlias = true;
    vimAlias = true;

    # Global options
    options = {
      # Line numbers
      number = true;
      relativenumber = true;

      # Search settings
      ignorecase = true;
      smartcase = true;
      incsearch = true;
      hlsearch = true;

      # Indentation
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      autoindent = true;
      smartindent = true;

      # UI improvements
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      wrap = false;
      scrolloff = 8;
      sidescrolloff = 8;

      # Splits
      splitright = true;
      splitbelow = true;

      # Backup and undo
      backup = false;
      writebackup = false;
      swapfile = false;
      undofile = true;
      undodir = "/home/${config.home.username}/.vim/undodir";

      # Timing
      updatetime = 250;
      timeoutlen = 300;

      # Mouse support
      mouse = "a";

      # Clipboard
      clipboard = "unnamedplus";

      # Folding
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
      foldlevel = 99;

      # Completion
      completeopt = "menu,menuone,noselect";

      # Command line
      wildmode = "longest:full,full";
      wildoptions = "pum";
    };

    # Global variables
    globals = {
      mapleader = " ";
      maplocalleader = " ";

      # Disable netrw (using nvim-tree instead)
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;

      # Python providers
      python3_host_prog = "${pkgs.python3}/bin/python";
    };

    # Color scheme
    colorschemes.catppuccin = {
      enable = true;
      flavour = "mocha";
      transparentBackground = false;
      integrations = {
        treesitter = true;
        native_lsp.enabled = true;
        telescope = true;
        gitsigns = true;
        nvimtree = true;
        which_key = true;
        indent_blankline.enabled = true;
      };
    };

    # Plugins configuration
    plugins = {
      # LSP Configuration
      lsp = {
        enable = true;
        servers = {
          # Nix
          nil_ls = {
            enable = true;
            settings = {
              formatting = {
                command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
              };
            };
          };

          # Rust
          rust-analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };

          # Go
          gopls = {
            enable = true;
          };

          # Python
          pyright = {
            enable = true;
          };

          # TypeScript/JavaScript
          tsserver = {
            enable = true;
          };

          # Bash
          bashls = {
            enable = true;
          };

          # YAML
          yamlls = {
            enable = true;
          };

          # JSON
          jsonls = {
            enable = true;
          };

          # Lua (for Neovim config)
          lua-ls = {
            enable = true;
            settings = {
              Lua = {
                diagnostics = {
                  globals = [ "vim" ];
                };
                workspace = {
                  library = [
                    "\${3rd}/luv/library"
                    "\${3rd}/busted/library"
                  ];
                };
              };
            };
          };
        };

        # LSP key mappings
        keymaps = {
          silent = true;
          lspBuf = {
            "gd" = "definition";
            "gD" = "declaration";
            "gi" = "implementation";
            "gt" = "type_definition";
            "gr" = "references";
            "K" = "hover";
            "<leader>ca" = "code_action";
            "<leader>rn" = "rename";
            "<leader>f" = "format";
          };
          diagnostic = {
            "[d" = "goto_prev";
            "]d" = "goto_next";
            "<leader>e" = "open_float";
            "<leader>q" = "setloclist";
          };
        };
      };

      # Completion
      cmp = {
        enable = true;
        settings = {
          snippet = {
            expand = "luasnip";
          };
          mapping = {
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          };
          sources = [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "buffer"; }
            { name = "path"; }
            { name = "nvim_lua"; }
          ];
          formatting = {
            format = "lspkind.cmp_format({ with_text = false, maxwidth = 50 })";
          };
        };
      };

      # Snippets
      luasnip = {
        enable = true;
        settings = {
          enable_autosnippets = true;
        };
      };

      # Treesitter for syntax highlighting
      treesitter = {
        enable = true;
        settings = {
          highlight = {
            enable = true;
            additional_vim_regex_highlighting = false;
          };
          indent = {
            enable = true;
          };
          ensure_installed = [
            "bash"
            "c"
            "cpp"
            "css"
            "dockerfile"
            "go"
            "html"
            "javascript"
            "json"
            "lua"
            "markdown"
            "nix"
            "python"
            "rust"
            "toml"
            "typescript"
            "vim"
            "yaml"
          ];
        };
      };

      # File explorer
      nvim-tree = {
        enable = true;
        disableNetrw = true;
        hijackNetrw = true;
        openOnTab = false;
        hijackCursor = false;
        updateCwd = true;
        diagnostics = {
          enable = true;
          icons = {
            hint = "";
            info = "";
            warning = "";
            error = "";
          };
        };
        updateFocusedFile = {
          enable = true;
          updateCwd = true;
        };
        view = {
          width = 30;
          side = "left";
          mappings = {
            custom_only = false;
            list = [
              { key = "l"; action = "edit"; }
              { key = "h"; action = "close_node"; }
              { key = "v"; action = "vsplit"; }
            ];
          };
        };
        renderer = {
          highlight_git = true;
          icons = {
            show = {
              file = true;
              folder = true;
              folder_arrow = true;
              git = true;
            };
          };
        };
      };

      # Fuzzy finder
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
          "<leader>fr" = "oldfiles";
          "<leader>fc" = "commands";
          "<leader>fk" = "keymaps";
        };
        settings = {
          defaults = {
            prompt_prefix = " ";
            selection_caret = " ";
            mappings = {
              i = {
                "<C-u>" = false;
                "<C-d>" = false;
              };
            };
          };
          pickers = {
            find_files = {
              theme = "dropdown";
            };
          };
        };
      };

      # Status line
      lualine = {
        enable = true;
        theme = "catppuccin";
        sections = {
          lualine_a = [ "mode" ];
          lualine_b = [ "branch" "diff" "diagnostics" ];
          lualine_c = [ "filename" ];
          lualine_x = [ "encoding" "fileformat" "filetype" ];
          lualine_y = [ "progress" ];
          lualine_z = [ "location" ];
        };
      };

      # Buffer line
      bufferline = {
        enable = true;
        settings = {
          options = {
            numbers = "none";
            close_command = "bdelete! %d";
            right_mouse_command = "bdelete! %d";
            left_mouse_command = "buffer %d";
            middle_mouse_command = null;
            indicator = {
              icon = "▎";
              style = "icon";
            };
            buffer_close_icon = "";
            modified_icon = "●";
            close_icon = "";
            left_trunc_marker = "";
            right_trunc_marker = "";
            max_name_length = 30;
            max_prefix_length = 30;
            tab_size = 21;
            diagnostics = "nvim_lsp";
            diagnostics_update_in_insert = false;
            show_buffer_icons = true;
            show_buffer_close_icons = true;
            show_close_icon = true;
            show_tab_indicators = true;
            persist_buffer_sort = true;
            separator_style = "slant";
            enforce_regular_tabs = true;
            always_show_bufferline = true;
          };
        };
      };

      # Git integration
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add = { text = "+"; };
            change = { text = "~"; };
            delete = { text = "_"; };
            topdelete = { text = "‾"; };
            changedelete = { text = "~"; };
          };
          current_line_blame = true;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 1000;
          };
        };
      };

      # Comments
      comment = {
        enable = true;
        settings = {
          opleader = {
            line = "gc";
            block = "gb";
          };
          toggler = {
            line = "gcc";
            block = "gbc";
          };
        };
      };

      # Auto pairs
      nvim-autopairs = {
        enable = true;
        settings = {
          check_ts = true;
          ts_config = {
            lua = [ "string" "source" ];
            javascript = [ "string" "template_string" ];
            java = false;
          };
        };
      };

      # Surround text objects
      nvim-surround = {
        enable = true;
      };

      # Indent guides
      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "│";
          };
          scope = {
            enabled = true;
            show_start = true;
            show_end = true;
          };
          exclude = {
            filetypes = [
              "help"
              "alpha"
              "dashboard"
              "neo-tree"
              "Trouble"
              "lazy"
              "mason"
            ];
          };
        };
      };

      # Which-key for key bindings
      which-key = {
        enable = true;
        registrations = {
          "<leader>f" = "Find";
          "<leader>g" = "Git";
          "<leader>l" = "LSP";
          "<leader>w" = "Window";
          "<leader>b" = "Buffer";
          "<leader>t" = "Tab";
        };
      };

      # Better escape
      better-escape = {
        enable = true;
        mapping = [ "jk" "jj" ];
      };

      # Markdown preview
      markdown-preview = {
        enable = true;
        settings = {
          auto_start = false;
          auto_close = true;
          refresh_slow = false;
          command_for_global = false;
          open_to_the_world = false;
          open_ip = "";
          browser = "firefox";
          echo_preview_url = false;
          browserfunc = "";
          preview_options = {
            mkit = { };
            katex = { };
            uml = { };
            maid = { };
            disable_sync_scroll = false;
            sync_scroll_type = "middle";
            hide_yaml_meta = true;
            sequence_diagrams = { };
            flowchart_diagrams = { };
            content_editable = false;
            disable_filename = false;
          };
          markdown_css = "";
          highlight_css = "";
          port = "8080";
          page_title = "「\${name}」";
          filetypes = [ "markdown" ];
        };
      };

      # Terminal integration
      toggleterm = {
        enable = true;
        settings = {
          size = 20;
          open_mapping = "<c-\\>";
          hide_numbers = true;
          shade_filetypes = { };
          shade_terminals = true;
          shading_factor = 2;
          start_in_insert = true;
          insert_mappings = true;
          persist_size = true;
          direction = "horizontal";
          close_on_exit = true;
          shell = "bash";
          float_opts = {
            border = "curved";
            winblend = 0;
            highlights = {
              border = "Normal";
              background = "Normal";
            };
          };
        };
      };

      # Additional helpful plugins
      nvim-colorizer = {
        enable = true;
        userDefaultOptions = {
          RGB = true;
          RRGGBB = true;
          names = true;
          RRGGBBAA = true;
          rgb_fn = true;
          hsl_fn = true;
          css = true;
          css_fn = true;
        };
      };

      # File icons
      web-devicons = {
        enable = true;
      };

      # LSP kind icons for completion
      lspkind = {
        enable = true;
        cmp = {
          enable = true;
          menu = {
            nvim_lsp = "[LSP]";
            luasnip = "[Snippet]";
            buffer = "[Buffer]";
            path = "[Path]";
            nvim_lua = "[Lua]";
          };
        };
      };
    };

    # Key mappings
    keymaps = [
      # General mappings
      {
        mode = "n";
        key = "<leader>w";
        action = ":w<CR>";
        options.desc = "Save file";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = ":q<CR>";
        options.desc = "Quit";
      }
      {
        mode = "n";
        key = "<leader>x";
        action = ":x<CR>";
        options.desc = "Save and quit";
      }

      # Window navigation
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Go to left window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Go to lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Go to upper window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Go to right window";
      }

      # Resize windows
      {
        mode = "n";
        key = "<C-Up>";
        action = ":resize +2<CR>";
        options.desc = "Increase window height";
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = ":resize -2<CR>";
        options.desc = "Decrease window height";
      }
      {
        mode = "n";
        key = "<C-Left>";
        action = ":vertical resize -2<CR>";
        options.desc = "Decrease window width";
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = ":vertical resize +2<CR>";
        options.desc = "Increase window width";
      }

      # Buffer navigation
      {
        mode = "n";
        key = "<Tab>";
        action = ":BufferLineCycleNext<CR>";
        options.desc = "Next buffer";
      }
      {
        mode = "n";
        key = "<S-Tab>";
        action = ":BufferLineCyclePrev<CR>";
        options.desc = "Previous buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = ":bdelete<CR>";
        options.desc = "Delete buffer";
      }

      # File explorer
      {
        mode = "n";
        key = "<leader>e";
        action = ":NvimTreeToggle<CR>";
        options.desc = "Toggle file explorer";
      }

      # Clear search highlighting
      {
        mode = "n";
        key = "<leader>/";
        action = ":nohl<CR>";
        options.desc = "Clear search highlight";
      }

      # Better indenting
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options.desc = "Indent left";
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options.desc = "Indent right";
      }

      # Move text up and down
      {
        mode = "v";
        key = "J";
        action = ":m '>+1<CR>gv=gv";
        options.desc = "Move text down";
      }
      {
        mode = "v";
        key = "K";
        action = ":m '<-2<CR>gv=gv";
        options.desc = "Move text up";
      }

      # Terminal mappings
      {
        mode = "t";
        key = "<C-h>";
        action = "<C-\\><C-N><C-w>h";
        options.desc = "Terminal left window nav";
      }
      {
        mode = "t";
        key = "<C-j>";
        action = "<C-\\><C-N><C-w>j";
        options.desc = "Terminal down window nav";
      }
      {
        mode = "t";
        key = "<C-k>";
        action = "<C-\\><C-N><C-w>k";
        options.desc = "Terminal up window nav";
      }
      {
        mode = "t";
        key = "<C-l>";
        action = "<C-\\><C-N><C-w>l";
        options.desc = "Terminal right window nav";
      }
    ];

    # Extra Lua configuration
    extraConfigLua = ''
      -- Additional Lua configuration
      
      -- Set up custom commands
      vim.api.nvim_create_user_command('Format', function()
        vim.lsp.buf.format()
      end, {})
      
      -- Auto commands
      local augroup = vim.api.nvim_create_augroup
      local autocmd = vim.api.nvim_create_autocmd
      
      -- Highlight on yank
      augroup('YankHighlight', { clear = true })
      autocmd('TextYankPost', {
        group = 'YankHighlight',
        callback = function()
          vim.highlight.on_yank({ higroup = 'IncSearch', timeout = '1000' })
        end
      })
      
      -- Auto format on save
      augroup('AutoFormat', { clear = true })
      autocmd('BufWritePre', {
        group = 'AutoFormat',
        pattern = { '*.nix', '*.rs', '*.go', '*.py', '*.js', '*.ts' },
        callback = function()
          vim.lsp.buf.format({ async = false })
        end
      })
      
      -- Close nvim-tree when it's the last buffer
      autocmd('BufEnter', {
        nested = true,
        callback = function()
          if #vim.api.nvim_list_wins() == 1 and
             vim.api.nvim_buf_get_name(0):match("NvimTree_") ~= nil then
            vim.cmd('quit')
          end
        end
      })
      
      -- Custom functions
      function _G.toggle_diagnostics()
        if vim.diagnostic.is_disabled() then
          vim.diagnostic.enable()
          print("Diagnostics enabled")
        else
          vim.diagnostic.disable()
          print("Diagnostics disabled")
        end
      end
      
      -- Key mapping for diagnostics toggle
      vim.keymap.set('n', '<leader>td', toggle_diagnostics, { desc = 'Toggle diagnostics' })
      
      -- Better terminal
      local Terminal = require('toggleterm.terminal').Terminal
      local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        float_opts = {
          border = "double",
        },
        on_open = function(term)
          vim.cmd("startinsert!")
          vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
        end,
        on_close = function(term)
          vim.cmd("startinsert!")
        end,
      })
      
      function _LAZYGIT_TOGGLE()
        lazygit:toggle()
      end
      
      vim.api.nvim_set_keymap("n", "<leader>gg", "<cmd>lua _LAZYGIT_TOGGLE()<CR>", {noremap = true, silent = true})
    '';

    # Extra plugins not available in nixvim yet
    extraPlugins = with pkgs.vimPlugins; [
      # Additional plugins can be added here
      vim-sleuth # Automatic indentation detection
      vim-repeat # Better repeat functionality
      plenary-nvim # Lua utilities (required by many plugins)
    ];
  };

  # Additional packages that work with Nixvim
  home.packages = with pkgs; [
    # Language servers (already configured in nixvim)
    nil # Nix LSP
    rust-analyzer # Rust LSP
    gopls # Go LSP
    pyright # Python LSP
    nodePackages.typescript-language-server # TypeScript LSP
    nodePackages.bash-language-server # Bash LSP
    yaml-language-server # YAML LSP

    # Formatters and linters
    nixpkgs-fmt # Nix formatter
    rustfmt # Rust formatter
    gofmt # Go formatter
    black # Python formatter
    prettier # JavaScript/TypeScript formatter
    shfmt # Shell script formatter

    # Tools for better development experience
    ripgrep # Fast search (for telescope)
    fd # Fast find (for telescope)
    lazygit # Git TUI

    # Terminal multiplexer (works well with toggleterm)
    tmux

    # Additional development tools
    git
    curl
    wget
    jq # JSON processor

    # Node.js for some language servers
    nodejs

    # Tree-sitter CLI for parser management
    tree-sitter

    # Clipboard tools for system integration
    xclip # X11 clipboard
    wl-clipboard # Wayland clipboard

    # Fonts for better display
    jetbrains-mono
    fira-code
    nerdfonts
  ];

  # Set environment variables for Nixvim
  home.sessionVariables = {
    EDITOR = lib.mkDefault "nvim";
    VISUAL = lib.mkDefault "nvim";
  };

  # Create undodir for persistent undo
  home.file.".vim/undodir/.keep".text = "";

  # Nixvim desktop entry
  xdg.desktopEntries.nixvim = {
    name = "Nixvim";
    comment = "Edit text files with Neovim configured via Nix";
    icon = "nvim";
    exec = "nvim %F";
    categories = [ "Utility" "TextEditor" "Development" ];
    mimeType = [
      "text/english"
      "text/plain"
      "text/x-makefile"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
      "application/x-yaml"
      "text/markdown"
    ];
  };
}
