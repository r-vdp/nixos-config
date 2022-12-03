{ inputs, lib, pkgs, ... }:

with lib;

{
  home = {
    packages = with pkgs; [
      (haskellPackages.ghcWithHoogle (hsPkgs: with hsPkgs; [
        stack
      ]))

      inputs.devenv.packages.${pkgs.system}.devenv
      python3
      ripgrep
    ];
  };

  programs = {
    direnv.enable = true;

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      withNodeJs = true;
      withPython3 = false;
      withRuby = false;
      extraConfig = ''luafile ${./nvim.lua}'';
      extraPackages = with pkgs; [
        # Haskell
        haskell-language-server

        # Python
        (pkgs.python3.withPackages (pyPkgs: with pyPkgs; [
          python-lsp-server
          pylsp-mypy
          mypy
          pyflakes
        ]))

        # Elm
        elmPackages.elm
        elm2nix
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
        go
        gopls

        # Needed for telescope-nvim
        fd
      ];
      plugins = with pkgs.vimPlugins;
        [
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
    };
  };
}

