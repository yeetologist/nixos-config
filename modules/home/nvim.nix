

{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      nil # Nix Language Server
      gcc
      nixfmt 
    ];

    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      telescope-nvim
      nvim-treesitter.withAllGrammars
      
      # Autocompletion Engine Dependencies
      nvim-cmp
      cmp-nvim-lsp
      luasnip
    ];

    # Note: Use extraLuaConfig, not initLua
    initLua = ''
      local set = vim.opt

      -- Line numbers
      set.relativenumber = true
      set.number = true

      -- Indentation and tabs
      set.tabstop = 4
      set.shiftwidth = 4
      set.autoindent = true
      set.expandtab = true

      -- Search settings
      set.ignorecase = true
      set.smartcase = true
      set.incsearch = true

      -- Appearance
      set.termguicolors = true
      set.background = "dark"
      set.signcolumn = "yes"
      set.cursorline = true
      set.colorcolumn = "80"

      -- Clipboard
      set.clipboard:append("unnamedplus")

      -- Backspace
      set.backspace = "indent,eol,start"

      -- Split windows
      set.splitbelow = true
      set.splitright = true

      -- dw/diw/ciw works on full-word (hyphen-aware)
      set.iskeyword:append("-")

      -- Keep cursor at least 8 rows from top/bottom
      set.scrolloff = 8

      -- Undo/swap/backup settings
      set.swapfile = false
      set.backup = false
      set.undodir = os.getenv("HOME") .. "/.vim/undodir"
      set.undofile = true

      -- Faster cursor hold
      set.updatetime = 50

      -- Leader key
      vim.g.mapleader = " "

      -- ==========================================
      -- KEYBINDS
      -- ==========================================
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})

      -- Press Space + fm to format the current file
      vim.keymap.set('n', '<leader>fm', function() vim.lsp.buf.format() end, {})

      -- ==========================================
      -- LSP CONFIGURATION
      -- ==========================================
      vim.lsp.config.nil_ls.settings = {
        ['nil'] = {
          formatting = {
            command = { 'nixfmt' },
          },
        },
      }
      vim.lsp.enable('nil_ls')

      -- ==========================================
      -- AUTOCOMPLETION ENGINE (nvim-cmp)
      -- ==========================================
      local cmp = require('cmp')
      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(), -- Force popup
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Press Enter to accept completion
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' }, -- Pull suggestions from 'nil'
        })
      })
    '';
  };
}