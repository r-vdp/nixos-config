{ lib, pkgs, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [
    haskell-language-server
    (haskellPackages.ghcWithHoogle (hsPkgs: with hsPkgs; [
      stack
    ]))

    elm2nix
    elmPackages.elm
    elmPackages.elm-language-server
    elmPackages.elm-format
    elmPackages.elm-review

    nodePackages.yaml-language-server

    rnix-lsp

    cargo
    gcc
    rustc
    rustfmt
    rust-analyzer

    # Needed for telescope-nvim
    ripgrep
    fd
  ];

  settings.system.withExtraPythonPackages = [
    (pyPkgs: with pyPkgs; [
      python-lsp-server
      pylsp-mypy
      mypy
      pyflakes
    ])
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

