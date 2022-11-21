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

  programs.nix-index.enable = true;
}
