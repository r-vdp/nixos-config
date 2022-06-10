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

  local function buf_keymap(...)
    vim.api.nvim_buf_set_keymap(bufnr, ...)
  end
  local function buf_set_option(...)
    vim.api.nvim_buf_set_option(bufnr, ...)
  end

  local opt_rm   = {noremap = false, silent = true}
  local opt_norm = {noremap = true, silent = true}

  buf_keymap('n', 'K',   ':lua vim.lsp.buf.hover()<CR>',              opt_rm)
  buf_keymap('n', 'ga',  ':lua vim.lsp.buf.code_action()<CR>',        opt_norm)
  buf_keymap('n', 'gd',  ':lua vim.lsp.buf.definition()<CR>',         opt_norm)
  buf_keymap('n', 'gD',  ':lua vim.lsp.buf.type_definition()<CR>',    opt_norm)
  buf_keymap('n', 'gi',  ':lua vim.lsp.buf.implementation()<CR>',     opt_norm)
  buf_keymap('n', 'g[',  ':lua vim.diagnostic.goto_prev()<CR>',   opt_norm)
  buf_keymap('n', 'g]',  ':lua vim.diagnostic.goto_next()<CR>',   opt_norm)
  buf_keymap('n', 'gl',  ':lua vim.diagnostic.setloclist()<CR>', opt_norm)
  buf_keymap('n', 'gr',  ':lua vim.lsp.buf.references()<CR>',         opt_norm)
  buf_keymap('n', 'gR',  ':lua vim.lsp.buf.rename()<CR>',             opt_norm)
  buf_keymap('n', '<leader>fs', ':lua vim.lsp.buf.workspace_symbol()<CR>', opt_norm)
  buf_keymap('n', '<leader>e', ':lua vim.diagnostic.open_float()<CR>', opt_norm)

  -- Mappings
  -- vim.api.nvim_buf_set_keymap(0, 'n', 'gd',
  --   '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(0, 'i', '<C-s>',
  --   '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)

  -- autoformat only for haskell
  if vim.api.nvim_buf_get_option(0, 'filetype') == 'haskell' then
    vim.api.nvim_command[[
      autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]]
  end
end

-- nvim-cmp supports additional completion capabilities.
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

nvim_lsp.hls.setup({
  on_attach = on_attach,
  settings = {
    haskell = {
      hlintOn = true,
      formattingProvider = "ormolu"
    }
  }
})

local servers = {"hls"}
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {debounce_text_changes = 150}
  })
end

