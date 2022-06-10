local nvim_lsp = require('lspconfig')

local on_attach = function(client, bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  local function buf_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  local opt_rm   = {noremap = false, silent = true}
  local opt_norm = {noremap = true, silent = true}

  buf_keymap('n', 'K',     ':lua vim.lsp.buf.hover()<CR>',           opt_rm)
  buf_keymap('n', 'gA',    ':lua vim.lsp.buf.code_action()<CR>',     opt_norm)
  buf_keymap('n', 'gd',    ':lua vim.lsp.buf.definition()<CR>',      opt_norm)
  buf_keymap('n', 'gD',    ':lua vim.lsp.buf.type_definition()<CR>', opt_norm)
  buf_keymap('n', '<leader>fs', ':lua vim.lsp.buf.workspace_symbol()<CR>',        opt_norm)
  buf_keymap('n', '<C-e>', ':lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opt_norm)
  buf_keymap('n', 'g[',    ':lua vim.lsp.diagnostic.goto_prev()<CR>',   opt_norm)
  buf_keymap('n', 'g]',    ':lua vim.lsp.diagnostic.goto_next()<CR>',   opt_norm)
  buf_keymap('n', 'gl',    ':lua vim.lsp.diagnostic.set_loclist()<CR>', opt_norm)
  buf_keymap('n', 'gr',    ':lua vim.lsp.buf.references()<CR>',         opt_norm)
  buf_keymap('n', 'gR',    ':lua vim.lsp.buf.rename()<CR>',             opt_norm)


  -- Mappings
  -- local opts = { noremap=true }
  -- vim.api.nvim_buf_set_keymap(0, 'n', '<c-]>',
  --   '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(0, 'n', 'K',
  --   '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(0, 'n', 'gd',
  --   '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(0, 'n', 'gD',
  --   '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(0, 'n', 'gr',
  --   '<cmd>lua vim.lsp.buf.references()<CR>', opts)

  -- vim.api.nvim_buf_set_keymap(0, 'n', '<leader>ca',
  --   '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(0, 'n', '<leader>cr',
  --   '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  -- vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ls',
  --   '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)

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

