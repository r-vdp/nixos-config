local xdg_state_home = vim.env.XDG_STATE_HOME

vim.opt.scrolloff = 3
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "·", nbsp = "+" } -- , eol = "¬"
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.showmatch = true
vim.opt.tabstop = 2
-- see multiple spaces as tabstops so <BS> does the right thing
vim.opt.softtabstop = 2
vim.opt.expandtab = true
-- width for autoindents
vim.opt.shiftwidth = 2
-- indent a new line the same amount as the line just typed
vim.opt.autoindent = true
-- Use conceal in MarkDown to format inline
vim.opt.conceallevel = 3
-- Split right and below
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.cursorline = true
vim.opt.relativenumber = true
-- set an 80 char column border
vim.opt.colorcolumn = "80"
-- height of the command window at the bottom
vim.opt.cmdheight = 0
-- get bash-like tab completions
vim.opt.wildmode = { longest = "full", "full" }
vim.opt.mouse = 'a'
-- using system clipboard
vim.opt.clipboard = "unnamedplus"
vim.opt.updatetime = 150

-- persistent undo history
vim.opt.undofile = true
vim.opt.backupdir = { xdg_state_home .. "/nvim/backup//" }
vim.opt.undodir = { xdg_state_home .. "/nvim/undo//" }
vim.opt.directory = { xdg_state_home .. "/nvim/swp//" }

-- Set up spell checking
vim.opt.spelllang = "en_gb"
local spell_augroup = "spell_augroup"
vim.api.nvim_create_augroup(spell_augroup, { clear = false })
vim.api.nvim_clear_autocmds({ buffer = bufnr, group = spell_augroup })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = spell_augroup,
  pattern = { "*.md" },
  callback = function() vim.wo.spell = true end
})
vim.api.nvim_create_autocmd({ "TermOpen" }, {
  group = spell_augroup,
  callback = function()
    vim.wo.spell = false
    vim.wo.relativenumber = false
  end
})

local general_augroup = "general_augroup"
vim.api.nvim_create_augroup(general_augroup, { clear = true })
-- reopen files at the position we were at
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  group = general_augroup,
  command = [[
    if line("'\"") >= 1 && line("'\"") <= line("$")
      exe "normal! g`\""
    endif
  ]]
})
-- Strip trailing whitespace on save
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = general_augroup,
  command = [[:%s/\s\+$//e]]
})

vim.cmd([[colorscheme jellybeans]])

vim.g.mapleader = ','

-- Suggestion from :checkhealth
vim.g.loaded_perl_provider = 0

-- https://essais.co/better-folding-in-neovim/
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.foldtext =
  [[ substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g') . ]] ..
  [[ ' ¬ (' . (v:foldend - v:foldstart + 1) . ' lines) ¬ ' . ]] ..
  [[ trim(getline(v:foldend)) ]]

local silent_opts = { silent = true }
vim.keymap.set('n', '<F1>', ':NERDTreeToggle<CR>')
vim.keymap.set('n', '<Space><Space>', ':w<CR>')
vim.keymap.set('i', 'jj', '<Esc>')
vim.keymap.set('n', '<Leader><Space>', ':nohl<CR>')
vim.keymap.set({'n', 'v'}, '<Tab>', '%')
vim.keymap.set('n', 'gb', ':buffers<CR>:buffer<Space>')
-- Move between buffers
vim.keymap.set('n', '<C-PageDown>', ':bprevious<CR>')
vim.keymap.set('n', '<C-PageUp>', ':bnext<CR>')
vim.keymap.set('n', '<C-h>', ':bprevious<CR>')
vim.keymap.set('n', '<C-l>', ':bnext<CR>')
-- Center the cursor on movement in normal mode
vim.keymap.set({'n', 'v'}, '<Up>', 'kzz', silent_opts)
vim.keymap.set({'n', 'v'}, '<Down>', 'jzz', silent_opts)
vim.keymap.set({'n', 'v'}, '<PageUp>', '<PageUp>zz', silent_opts)
vim.keymap.set({'n', 'v'}, '<PageDown>', '<PageDown>zz', silent_opts)
vim.keymap.set({'n', 'v'}, 'k', 'kzz', silent_opts)
vim.keymap.set({'n', 'v'}, 'j', 'jzz', silent_opts)
vim.keymap.set({'n', 'v'}, '<C-u>', '<C-u>zz', silent_opts)
vim.keymap.set({'n', 'v'}, '<C-d>', '<C-d>zz', silent_opts)

local telescope_builtin = require('telescope.builtin')
vim.keymap.set('n', '<Leader>ff', telescope_builtin.find_files)
vim.keymap.set('n', '<Leader>fb', telescope_builtin.buffers)
vim.keymap.set('n', '<Leader>fg', telescope_builtin.live_grep)
vim.keymap.set('n', '<Leader>fc', telescope_builtin.command_history)
vim.keymap.set('n', '<Leader>fm', telescope_builtin.man_pages)
vim.keymap.set('n', '<Leader>ft', telescope_builtin.treesitter)
vim.keymap.set('n', '<Leader>fd', telescope_builtin.diagnostics)
vim.keymap.set('n', '<Leader>fws', telescope_builtin.lsp_workspace_symbols)

-- Go back to normal mode in a terminal buffer
vim.keymap.set('t', '<C-Space>', '<C-\\><C-n>')
vim.keymap.set('n', '<Leader>t', ':vsplit +term<CR>')
vim.keymap.set('n', '<Leader>T', ':split +term<CR>')

require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'auto',
    component_separators = { left = '|', right = '|'},
    section_separators = { left = '»', right = '«'},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    globalstatus = false,
    refresh = {
      statusline = 1000,
      tabline = 1000,
      winbar = 1000,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {{
      'buffers',
      mode = 2,
      buffers_color = {
        active = { fg = 'white', gui = 'italic,bold' },
        inactive = { fg = '#8197bf' }
      }
    }},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  },
  inactive_winbar = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {{
      'buffers',
      mode = 2,
      buffers_color = {
        active = { fg = '#8197bf', gui = 'italic' },
        inactive = { fg = 'grey' }
      }
    }},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {}
  },
  extensions = {}
}

local nvim_lsp = require('lspconfig')

local config = {
  virtual_text = true,
  -- show signs
  --signs = {
  --  active = signs,
  --},
  update_in_insert = true,
  underline = true,
  severity_sort = true,
  float = {
    focus = false,
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
}

vim.diagnostic.config(config)

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  local opts = { silent = true, buffer = bufnr }

  vim.keymap.set('n', 'K',  function() vim.lsp.buf.hover() end,           opts)
  vim.keymap.set('n', 'ga', function() vim.lsp.buf.code_action() end,     opts)
  vim.keymap.set('n', 'gL', function() vim.lsp.codelens.run() end,        opts)
  vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end,      opts)
  vim.keymap.set('n', 'gD', function() vim.lsp.buf.type_definition() end, opts)
  vim.keymap.set('n', 'gi', function() vim.lsp.buf.implementation() end,  opts)
  vim.keymap.set('n', 'g[', function() vim.diagnostic.goto_prev() end,    opts)
  vim.keymap.set('n', 'g]', function() vim.diagnostic.goto_next() end,    opts)
  vim.keymap.set('n', 'gl', function() vim.diagnostic.setloclist() end,   opts)
  vim.keymap.set('n', 'gr', function() vim.lsp.buf.references() end,      opts)
  vim.keymap.set('n', 'gR', function() vim.lsp.buf.rename() end,          opts)
  vim.keymap.set('n', 'gF', function() vim.lsp.buf.format() end, opts)
  vim.keymap.set('n', '<leader>fs', function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set('n', '<leader>e', function() vim.diagnostic.open_float() end, opts)

  -- Mappings
  -- vim.api.nvim_buf_set_keymap(0, 'n', 'gd',
  --   '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(0, 'i', '<C-s>',
  --   '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

  local lsp_augroup = "lsp_augroup"
  vim.api.nvim_create_augroup(lsp_augroup, { clear = false })
  vim.api.nvim_clear_autocmds({ buffer = bufnr, group = lsp_augroup })
  vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = lsp_augroup,
    buffer = bufnr,
    -- Set a max timeout of 10000 to give the formatter a bit more time.
    callback = function() vim.lsp.buf.formatting_sync(nil, 10000) end
  })
  if vim.bo.filetype == "haskell" then
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "InsertLeave" }, {
      group = lsp_augroup,
      buffer = bufnr,
      -- automatically refresh codelenses, which can then be run with gL
      callback = function() vim.lsp.codelens.refresh() end
    })
  end
end

-- nvim-cmp supports additional completion capabilities.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

local servers = {"hls", "elmls", "rnix", "yamlls", "pylsp"}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      haskell = {
        hlintOn = true,
        formattingProvider = "ormolu"
      },
      elmLS = {
        elmReviewDiagnostics = "warning",
        disableElmLSDiagnostics = false
      },
      yaml = {
        format = {
          enable = true,
          printWidth = 100,
          bracketSpacing = true,
          proseWrap = "always"
        },
        validate = true,
        completion = true
      },
      pylsp = {
        plugins = {
          pylsp_mypy = {
            enable = true
          },
          pycodestyle = {
            -- W503: deprecated in favour of W504
            ignore = {'W503'},
            maxLineLength = 100
          }
        }
      }
    }
  })
end

local cmp = require('cmp')

cmp.setup({
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<Tab>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true
    }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    -- { name = 'vsnip' }, -- For vsnip users.
    -- { name = 'luasnip' }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
    { name = 'path' },
    { name = 'buffer' },
  }),
  --formatting = {
  --  format = lspkind.cmp_format {
  --    with_text = true,
  --    menu = {
  --      buffer   = "[buf]",
  --      nvim_lsp = "[LSP]",
  --      path     = "[path]",
  --    },
  --  },
  --},
  experimental = {
    ghost_text = true
  }
})

