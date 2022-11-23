{ config, lib, pkgs, nix-index-database, ... }:

with lib;

let
  inherit (lib.hm) dag;
in
{
  home.file = {
    # Put the pre-generated nix-index database in place,
    # used for command-not-found.
    ".cache/nix-index/files".source =
      nix-index-database.legacyPackages.${pkgs.system}.database;
  };

  programs = {
    nix-index.enable = true;

    bash.initExtra = ''
      # Create an empty intial profile
      # Some tools, like NixOS' command-not-found, check for
      # ~/.nix-profile/manifest.json to decide whether we use the nix3 interface.
      if [[ ! -e "''${HOME}/.nix-profile/manifest.json" ]]; then
        nix profile install "nixpkgs#hello"
        nix profile remove 0
        nix profile wipe-history
      fi
    '';
  };
}
