{ lib, pkgs, ... }:

with lib;

{
  environment.systemPackages = with pkgs; [
    # Haskell
    haskell-language-server
    (haskellPackages.ghcWithHoogle (hsPkgs: with hsPkgs; [
      stack
    ]))

    # Elm
    elm2nix
    elmPackages.elm
    elmPackages.elm-language-server
    elmPackages.elm-format
    elmPackages.elm-review

    # YAML
    nodePackages.yaml-language-server

    # Nix
    rnix-lsp

    # Rust
    cargo
    gcc
    rustc
    rustfmt
    rust-analyzer

    # Go
    gopls

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
          cmp-buffer
          cmp_luasnip
          cmp-nvim-lsp
          dracula-vim
          elm-vim
          haskell-vim
          indent-blankline-nvim
          lualine-nvim
          luasnip
          nerdtree
          nvim-cmp
          nvim-lspconfig
          telescope-nvim
          vim-nix
          vim-markdown
          vim-colorschemes
        ];
        opt = [ ];
      };
    };
    withRuby = false;
    withPython3 = false;
    withNodeJs = true;
  };
}

