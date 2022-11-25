{ lib, ... }:
{
  imports = import ../import-dir.nix { inherit lib; fromDir = ./.; };
}

