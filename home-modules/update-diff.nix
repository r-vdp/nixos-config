{ pkgs, ... }:

{
  home.activation.diff = ''
    if [[ -n "$oldGenPath" && -n "$newGenPath" ]]; then
      echo "Home manager closure diff:"
      $DRY_RUN_CMD ${pkgs.nix}/bin/nix store diff-closures "$oldGenPath" "$newGenPath"
    fi
  '';
}

