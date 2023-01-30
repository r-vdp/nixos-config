{ lib, ... }:
{
  imports = import ../import-dir.nix { inherit lib; fromDir = ./.; };

  config.nixpkgs.config.allowUnfree = true;
}
