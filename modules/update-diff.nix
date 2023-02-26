{ lib, pkgs, ... }:

{
  system.activationScripts.diff = ''
    if [[ -e /run/current-system ]]; then
      echo "NixOS system closure diff:"
      ${lib.getExe pkgs.nix} store diff-closures /run/current-system "$systemConfig"
    fi
  '';
}
