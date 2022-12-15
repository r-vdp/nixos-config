local xdg_state_home = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state/")

vim.opt.scrolloff = 3
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "·", nbsp = "+" } -- , eol = "¬"
-- Do not consider '=' to be part of filenames,
-- so we can use gf in systemd unit files.
vim.opt.isfname:remove("=")
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
-- enabling both number and relativenumber means hybrid mode
vim.opt.number = true
vim.opt.relativenumber = true
-- set an 80 char column border
vim.opt.colorcolumn = "80"
-- height of the command window at the bottom
vim.opt.cmdheight = 0
-- get bash-like tab completions
vim.opt.wildmode = { longest = "full", "full" }
vim.opt.mouse = "a"
-- using system clipboard
vim.opt.clipboard = "unnamedplus"
vim.opt.updatetime = 150

vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.shortmess = vim.opt.shortmess + "c"

-- persistent undo history
vim.opt.undofile = true
vim.opt.backupdir = { xdg_state_home .. "/nvim/backup//" }
vim.opt.undodir = { xdg_state_home .. "/nvim/undo//" }
vim.opt.directory = { xdg_state_home .. "/nvim/swp//" }

-- Copy paste over SSH
-- See https://rumpelsepp.org/blog/nvim-clipboard-through-ssh/
if vim.env.TMUX then
  vim.g.clipboard = {
    name = "tmux",
    copy = {
      ["+"] = { "tmux", "load-buffer", "-w", "-" },
      ["*"] = { "tmux", "load-buffer", "-w", "-" },
    },
    paste = {
      ["+"] = { "bash", "-c",
        "tmux refresh-client -l && sleep 0.2 && tmux save-buffer -" },
      ["*"] = { "bash", "-c",
        "tmux refresh-client -l && sleep 0.2 && tmux save-buffer -" },
    },
    cache_enabled = false,
  }
end

-- Set up spell checking
vim.opt.spelllang = "en_gb"
local spell_augroup = "spell_augroup"
vim.api.nvim_create_augroup(spell_augroup, { clear = true })
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = spell_augroup,
  pattern = { "*.md" },
  callback = function() vim.wo.spell = true end
})
-- Autocommands for terminal buffers
local term_augroup = "term_augroup"
vim.api.nvim_create_augroup(term_augroup, { clear = true })
vim.api.nvim_create_autocmd({ "TermOpen" }, {
  group = term_augroup,
  callback = function()
    vim.wo.spell = false
    vim.wo.number = false
    vim.wo.relativenumber = false
  end
})
-- Restore line numbers if we're not in a term
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = term_augroup,
  callback = function()
    if vim.o.buftype ~= "terminal" then
      vim.wo.number = true
      vim.wo.relativenumber = true
    end
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
  command = [[
    :%s/\s\+$//e
    :nohl
  ]]
})

-- Match systemd files in the nix store
local function systemd_patterns()
  local systemd_prefix = "/nix/store/.*/.*%."
  local systemd_exts = { "automount", "mount", "path", "service", "socket",
    "swap", "target", "timer" }
  local patterns = {}
  for _, ext in ipairs(systemd_exts) do
    patterns[systemd_prefix .. ext] = "systemd"
  end
  return patterns
end

vim.filetype.add({
  pattern = systemd_patterns()
})

vim.cmd([[colorscheme jellybeans]])

vim.g.mapleader = ","

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
vim.keymap.set("n", "<F1>", ":NERDTreeToggle<CR>", silent_opts)
vim.keymap.set("n", "<Space><Space>", ":silent w<CR>", silent_opts)
vim.keymap.set("i", "jj", "<Esc>", silent_opts)
vim.keymap.set("n", "<Leader><Space>", ":nohl<CR>", silent_opts)
vim.keymap.set({ "n", "v" }, "<Tab>", "%", silent_opts)
-- Move between buffers
vim.keymap.set("n", "<C-PageDown>", ":bprevious<CR>", silent_opts)
vim.keymap.set("n", "<C-PageUp>", ":bnext<CR>", silent_opts)
vim.keymap.set("n", "<C-h>", ":bprevious<CR>", silent_opts)
vim.keymap.set("n", "<C-l>", ":bnext<CR>", silent_opts)
-- Center the cursor on movement in normal mode
vim.keymap.set({ "n", "v" }, "<Up>", "kzz", silent_opts)
vim.keymap.set({ "n", "v" }, "<Down>", "jzz", silent_opts)
vim.keymap.set({ "n", "v" }, "<PageUp>", "<PageUp>zz", silent_opts)
vim.keymap.set({ "n", "v" }, "<PageDown>", "<PageDown>zz", silent_opts)
vim.keymap.set({ "n", "v" }, "k", "kzz", silent_opts)
vim.keymap.set({ "n", "v" }, "j", "jzz", silent_opts)
vim.keymap.set({ "n", "v" }, "<C-u>", "<C-u>zz", silent_opts)
vim.keymap.set({ "n", "v" }, "<C-d>", "<C-d>zz", silent_opts)

local telescope_builtin = require("telescope.builtin")
vim.keymap.set("n", "<Leader>ff", telescope_builtin.find_files, silent_opts)
vim.keymap.set("n", "<Leader>fb", telescope_builtin.buffers, silent_opts)
vim.keymap.set("n", "<Leader>b", telescope_builtin.buffers, silent_opts)
vim.keymap.set("n", "<Leader>fg", telescope_builtin.live_grep, silent_opts)
vim.keymap.set("n", "<Leader>fc", telescope_builtin.command_history, silent_opts)
vim.keymap.set("n", "<Leader>fm", telescope_builtin.man_pages, silent_opts)
vim.keymap.set("n", "<Leader>ft", telescope_builtin.treesitter, silent_opts)
vim.keymap.set("n", "<Leader>fd", telescope_builtin.diagnostics, silent_opts)
vim.keymap.set("n", "<Leader>fws", telescope_builtin.lsp_workspace_symbols, silent_opts)

-- Go back to normal mode in a terminal buffer
vim.keymap.set("t", "<C-Space>", "<C-\\><C-n>", silent_opts)
vim.keymap.set("n", "<Leader>t", ":vsplit +term<CR>", silent_opts)
vim.keymap.set("n", "<Leader>T", ":split +term<CR>", silent_opts)

local function num_of_lines()
  return vim.fn.line("$")
end

require("lualine").setup {
  options = {
    icons_enabled = true,
    theme = "auto",
    component_separators = { left = "", right = "" },
    section_separators = { left = "", right = "" },
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
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location", num_of_lines }
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "encoding", "fileformat", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location", num_of_lines }
  },
  tabline = {
    lualine_a = { {
      "buffers",
      mode = 4,
    } },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = { {
      "tabs",
      mode = 3,
    } }
  },
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}

local nvim_lsp = require("lspconfig")

local config = {
  virtual_text = true,
  -- show signs
  signs = true,
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

-- Ignore hints labelled as "Unnecessary", eg unused variables prefixed with "_".
-- See https://github.com/neovim/neovim/issues/17757
local unnecessary_hints_ns = vim.api.nvim_create_namespace("unnecessary_hints_ns")
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(_, result, ctx, _config)
  local bufnr = vim.uri_to_bufnr(result.uri)
  if not bufnr then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, unnecessary_hints_ns, 0, -1)
  local real_diags = {}
  for _, diag in pairs(result.diagnostics) do
    if diag.severity == vim.lsp.protocol.DiagnosticSeverity.Hint
        and diag.tags ~= nil
        and vim.tbl_contains(diag.tags, vim.lsp.protocol.DiagnosticTag.Unnecessary) then
      pcall(vim.api.nvim_buf_set_extmark, bufnr, unnecessary_hints_ns,
        diag.range.start.line, diag.range.start.character, {
        end_row = diag.range["end"].line,
        end_col = diag.range["end"].character,
        hl_group = "Dim",
      })
    else
      table.insert(real_diags, diag)
    end
  end
  result.diagnostics = real_diags
  vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
end

local on_attach = function(_client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  local opts = { silent = true, buffer = bufnr }

  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "ga", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "gL", function() vim.lsp.codelens.run() end, opts)
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "gD", function() vim.lsp.buf.type_definition() end, opts)
  vim.keymap.set("n", "gi", function() vim.lsp.buf.implementation() end, opts)
  vim.keymap.set("n", "g[", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "g]", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "gl", function() vim.diagnostic.setloclist() end, opts)
  vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "gR", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("n", "gF", function() vim.lsp.buf.format() end, opts)
  vim.keymap.set("n", "<leader>fs", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "<leader>e", function() vim.diagnostic.open_float() end, opts)

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
    callback = function()
      vim.lsp.buf.formatting_sync(nil, 10000)
    end
  })
  -- Show diagnostic popup on cursor hover
  vim.api.nvim_create_autocmd("CursorHold", {
    group = lsp_augroup,
    buffer = bufnr,
    callback = function()
      vim.diagnostic.open_float(nil, { focusable = false })
    end
  })
  if (vim.bo.filetype == "haskell" or vim.bo.filetype == "rust") then
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "InsertLeave" }, {
      group = lsp_augroup,
      buffer = bufnr,
      -- automatically refresh codelenses, which can then be run with gL
      callback = function()
        vim.lsp.codelens.refresh()
      end
    })
  end
end

-- nvim-cmp supports additional completion capabilities.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

local servers = {
  "elmls",
  "gopls",
  "hls",
  "pylsp",
  "rnix",
  "rust_analyzer",
  "sumneko_lua",
  "yamlls",
}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      elmLS = {
        elmReviewDiagnostics = "warning",
        disableElmLSDiagnostics = false
      },
      gopls = {
        experimentalPostfixCompletions = true,
        analyses = {
          unusedparams = true,
          shadow = true,
        },
        staticcheck = true,
      },
      haskell = {
        hlintOn = true,
        formattingProvider = "ormolu"
      },
      pylsp = {
        plugins = {
          pylsp_mypy = {
            enable = true
          },
          pycodestyle = {
            -- W503: deprecated in favour of W504
            ignore = { "W503" },
            maxLineLength = 100
          }
        }
      },
      ["rust-analyzer"] = {
        imports = {
          granularity = {
            group = "module",
          },
          prefix = "self",
        },
        cargo = {
          buildScripts = {
            enable = true,
          },
        },
        procMacro = {
          enable = true,
        },
      },
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
        format = {
          defaultConfig = {
            quote_style = "double",
          },
        },
        telemetry = {
          enable = false,
        },
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
    }
  })
end

local cmp = require("cmp")

cmp.setup({
  preselect = cmp.PreselectMode.None,
  snippet = {
    -- REQUIRED - you must specify a snippet engine
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
      -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
      -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
    end,
  },
  window = {
    -- completion = cmp.config.window.bordered(),
    -- documentation = cmp.config.window.bordered(),
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-n>"] = cmp.mapping.select_next_item(),
    -- Add tab support
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true
    }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    -- { name = 'vsnip' }, -- For vsnip users.
    { name = "luasnip" }, -- For luasnip users.
    -- { name = 'ultisnips' }, -- For ultisnips users.
    -- { name = 'snippy' }, -- For snippy users.
    { name = "path" },
    { name = "buffer" },
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
