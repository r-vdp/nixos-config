{ inputs, lib, pkgs, ... }:

with lib;

{
  home = {
    packages = with pkgs; [
      (haskellPackages.ghcWithHoogle (hsPkgs: with hsPkgs; [
        stack
      ]))

      # Needed for telescope-nvim, modern `find` alternative
      fd
      inputs.devenv.packages.${pkgs.system}.devenv
      python3
      # Needed for telescope-nvim, modern grep alternative
      ripgrep
      # Allow Neovim to sync the unnamed register with the Wayland clipboard.
      wl-clipboard
    ];

    sessionVariables.EDITOR = "nvim";
  };

  programs = {
    direnv = {
      enable = true;
      # devenv can be slow to load, we don't need a warning every time
      config.global.warn_timeout = "3m";
    };

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
        # Bash
        shellcheck

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

        # Lua
        sumneko-lua-language-server

        # YAML
        nodePackages.yaml-language-server

        # Nix
        deadnix
        rnix-lsp
        statix

        # Rust
        cargo
        gcc
        rustc
        rustfmt
        rust-analyzer

        # Go
        go
        gopls

        editorconfig-checker
      ];
      plugins = with pkgs.vimPlugins;
        [
          (nvim-treesitter.withPlugins (const pkgs.tree-sitter.allGrammars))
          cmp-buffer
          cmp_luasnip
          cmp-nvim-lsp
          editorconfig-nvim
          elm-vim
          gitsigns-nvim
          haskell-vim
          impatient-nvim
          indent-blankline-nvim
          lualine-nvim
          luasnip
          nerdtree
          nvim-cmp
          nvim-lspconfig
          nvim-ts-rainbow
          null-ls-nvim
          telescope-nvim
          vim-nix
          vim-markdown
          vim-colorschemes
        ];
    };
  };
}
