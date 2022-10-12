{ lib, pkgs, ... }:

with lib;

{
  # Disable the default neovim config
  #settings.vim.enable = false;

  environment.systemPackages = with pkgs; [
    rnix-lsp
    nodePackages.yaml-language-server
    # Needed for telescope-nvim
    (pkgs.python3.withPackages (pythonPackages: with pythonPackages; [
      python-lsp-server
      pylsp-mypy
      mypy
      pyflakes
    ]))
    ripgrep
    fd
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    configure = {
      customRC = ''
        luafile ${./nvim.lua}
      '';
      packages.nix = with pkgs.vimPlugins; {
        start = [
          (nvim-treesitter.withPlugins (const pkgs.tree-sitter.allGrammars))
          vim-nix
          haskell-vim
          elm-vim
          vim-markdown
          dracula-vim
          lualine-nvim
          vim-colorschemes
          indent-blankline-nvim
          nerdtree
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          luasnip
          cmp_luasnip
          telescope-nvim
        ];
        opt = [ ];
      };
    };
    withRuby = false;
    withPython3 = false;
    withNodeJs = true;
  };
}

