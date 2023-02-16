{ inputs, config, lib, pkgs, ... }:

{
  options = {
    home.settings.neovim.enableFullDevelopEnv = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = {
    home = {
      packages = with pkgs; [
        (haskellPackages.ghcWithHoogle (hsPkgs: with hsPkgs; [
          stack
        ]))

        cargo

        # Needed for telescope-nvim, modern `find` alternative
        fd
        fzf
        inputs.devenv.packages.${pkgs.system}.devenv
        python3
        # Needed for telescope-nvim, modern grep alternative
        ripgrep
        # Allow Neovim to sync the unnamed register with the Wayland clipboard.
        wl-clipboard
      ];
    };

    programs = {
      direnv = {
        enable = true;
        # devenv can be slow to load, we don't need a warning every time
        config.global.warn_timeout = "3m";

        nix-direnv.enable = true;
      };

      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
        withNodeJs = true;
        withPython3 = false;
        withRuby = false;
        extraConfig = ''luafile ${./nvim.lua}'';
        extraPackages = with pkgs; ([
          # Bash
          shellcheck

          # Python
          (python3.withPackages (pyPkgs: with pyPkgs; [
            python-lsp-server
            python-lsp-black
            pylsp-mypy
            mypy
            pyflakes
          ]))

          # YAML
          nodePackages.yaml-language-server

          # Nix
          #deadnix
          #rnix-lsp
          #statix
          nil
          nixpkgs-fmt

          editorconfig-checker
        ] ++ lib.optionals config.home.settings.neovim.enableFullDevelopEnv [
          # Haskell
          haskell-language-server

          # Elm
          elmPackages.elm
          elm2nix
          elmPackages.elm-language-server
          elmPackages.elm-format
          elmPackages.elm-review

          # Lua
          lua-language-server

          # Perl
          perlPackages.PLS

          # Rust
          gcc
          rustc
          rustfmt
          rust-analyzer

          # Go
          go
          gopls
        ]);
        plugins = with pkgs.vimPlugins; [
          #(nvim-treesitter.withPlugins (const pkgs.tree-sitter.allGrammars))
          cmp-buffer
          cmp-cmdline
          cmp-latex-symbols
          cmp_luasnip
          cmp-nvim-lsp
          cmp-path
          diffview-nvim
          direnv-vim
          editorconfig-nvim
          elm-vim
          git-blame-nvim
          gitsigns-nvim
          haskell-vim
          impatient-nvim
          indent-blankline-nvim
          lualine-nvim
          luasnip
          nvim-cmp
          nvim-lspconfig
          nvim-tree-lua
          #nvim-ts-rainbow
          nvim-web-devicons
          null-ls-nvim
          telescope-nvim
          vim-nix
          vim-markdown
          vim-colorschemes
        ];
      };
    };
  };
}
