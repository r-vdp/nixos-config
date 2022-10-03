vim.opt.compatible = false -- disable compatibility to old-time vi
vim.opt.encoding = "utf-8"
vim.opt.scrolloff = 3
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "·" } -- , eol = "¬"
vim.opt.termguicolors = true
vim.opt.hlsearch = true --highlight search
vim.opt.incsearch = true -- incremental search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.showmatch = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2 -- see multiple spaces as tabstops so <BS> does the right thing
vim.opt.expandtab = true
vim.opt.shiftwidth = 2 -- width for autoindents
vim.opt.autoindent = true -- indent a new line the same amount as the line just typed
vim.opt.hidden = true -- Enable hidden buffers with unsaved changes
-- Split right and below
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ruler = true
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.laststatus = 2
vim.opt.colorcolumn = "80" -- set an 80 char column border
vim.opt.cmdheight = 1 -- height of the command window at the bottom
vim.opt.wildmenu = true
vim.opt.wildmode = { list = "longest" } -- get bash-like tab completions
vim.opt.ttyfast = true -- Speed up scrolling in Vim
vim.opt.undofile = true
vim.opt.mouse = 'a' -- 'v'
vim.opt.clipboard = "unnamedplus" -- using system clipboard
vim.opt.updatetime = 150

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

vim.cmd([[
  colorscheme jellybeans
  syntax on
  filetype plugin on
  filetype plugin indent on   " allow auto-indenting depending on file type

  silent !mkdir ~/.cache/vim > /dev/null 2>&1
  set backupdir=~/.cache/vim " Directory to store backup files.
]])

vim.g.mapleader = ','

-- Suggestion from :checkhealth
vim.g.loaded_perl_provider = 0

-- Airline
vim.g.airline_theme = 'bubblegum'
vim.g.airline_powerline_fonts = 1
vim.g['airline#extensions#tabline#enabled'] = 1
vim.g['airline#extensions#tabline#left_sep'] = ' '
vim.g['airline#extensions#tabline#left_alt_sep'] = '|'

if vim.g.airline_symbols == nil then
  vim.cmd([[
    " create the value as an empty table if it didn't exist yet
    let g:airline_symbols = {}

    " let g:airline_symbols.linenr = '␊'
    " let g:airline_symbols.linenr = '␤'
    " let g:airline_symbols.linenr = '¶'
    " let g:airline_symbols.paste = 'Þ'
    " let g:airline_symbols.paste = '∥'
    " let g:airline_symbols.linenr = '␊'
    " let g:airline_symbols.linenr = '␤'
    " let g:airline_symbols.linenr = '¶'
    let g:airline_symbols.linenr = '⮃'
    let g:airline_symbols.colnr = '⮀'
    let g:airline_symbols.branch = '⎇'
    let g:airline_symbols.paste = 'ρ'
    let g:airline_symbols.whitespace = 'Ξ'
  ]])
end

vim.g.airline_left_sep = '»'
-- let g:airline_left_sep = '▶'
vim.g.airline_right_sep = '«'
-- let g:airline_right_sep = '◀'

-- https://essais.co/better-folding-in-neovim/
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.foldtext =
  [[ substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g') . ]] ..
  [[ ' ¬ (' . (v:foldend - v:foldstart + 1) . ' lines) ¬ ' . ]] ..
  [[ trim(getline(v:foldend)) ]]

-- reopen files at the position we were at
vim.api.nvim_command([[
  autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif
]])

-- remove trailing whitespace
vim.api.nvim_command([[
  autocmd BufWritePre * :%s/\s\+$//e
]])

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
-- Center the cursor on movement in normal mode
vim.keymap.set('n', '<Up>', 'kzz', silent_opts)
vim.keymap.set('n', '<Down>', 'jzz', silent_opts)
vim.keymap.set('n', '<PageUp>', '<PageUp>zz', silent_opts)
vim.keymap.set('n', '<PageDown>', '<PageDown>zz', silent_opts)

-- Go back to normal mode in a terminal buffer
vim.keymap.set('t', '<C-Space>', '<C-\\><C-n>')
vim.keymap.set('n', '<Leader>t', ':vsplit +term<CR>')
vim.keymap.set('n', '<Leader>T', ':split +term<CR>')


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
  vim.keymap.set('n', 'gF', function() vim.lsp.buf.formatting_sync() end, opts)
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
    flags = {debounce_text_changes = 150},
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
      vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
  --    -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
  --    -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
  --    -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
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

