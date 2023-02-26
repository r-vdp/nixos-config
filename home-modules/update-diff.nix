{ lib, pkgs, ... }:

{
  # The HM activate script runs with "set -u", and so errors on unbound variables.
  # We need to check with "-v" if a variable exists before we can use it.
  home.activation.diff = ''
    if [[ -v "oldGenPath" && -v "newGenPath" ]]; then
      echo "Home manager closure diff:"
      $DRY_RUN_CMD ${lib.getExe pkgs.nix} store diff-closures "$oldGenPath" "$newGenPath"
    fi
  '';
}
