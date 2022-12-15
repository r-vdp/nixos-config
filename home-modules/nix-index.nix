{ inputs, pkgs, ... }:

{
  home.file = {
    # Put the pre-generated nix-index database in place,
    # used for command-not-found.
    ".cache/nix-index/files".source =
      inputs.nix-index-database.legacyPackages.${pkgs.system}.database;
  };

  programs =
    let
      genericInitExtra = ''
        # Create an empty intial profile
        # Some tools, like NixOS' command-not-found, check for
        # ~/.nix-profile/manifest.json to decide whether we use the nix3 interface.
        if [[ ! -e "''${HOME}/.nix-profile/manifest.json" ]]; then
          nix profile install "nixpkgs#hello"
          nix profile remove 0
          nix profile wipe-history
        fi
      '';
    in
    {
      nix-index.enable = true;

      bash.initExtra = genericInitExtra;
      zsh.initExtra = genericInitExtra;
    };
}
