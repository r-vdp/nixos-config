{ pkgs, ... }:

{
  # Disable the default neovim config
  settings.vim.enable = false;

  environment.systemPackages = with pkgs; [
    rnix-lsp
    nodePackages.yaml-language-server
  ];

  settings.packages.python_package =
    pkgs.python3.withPackages (pythonPackages: with pythonPackages; [
      python-lsp-server
      pylsp-mypy
      mypy
      pyflakes
    ]);

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
          (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
          vim-nix
          haskell-vim
          elm-vim
          vim-markdown
          dracula-vim
          lualine-nvim
          bufferline-nvim
          vim-colorschemes
          indent-blankline-nvim
          nerdtree
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          luasnip
          cmp_luasnip
        ];
        opt = [ ];
      };
    };
    withRuby = false;
    withPython3 = false;
    withNodeJs = true;
  };
}

