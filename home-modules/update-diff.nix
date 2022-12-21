{ pkgs, ... }:

{
  home.activation.diff = ''
    if [[ -e /run/current-system ]]; then
      echo "Home manager closure diff:"
      $DRY_RUN_CMD ${pkgs.nix}/bin/nix store diff-closures "$oldGenPath" "$newGenPath"
    fi
  '';
}

