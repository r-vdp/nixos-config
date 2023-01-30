{ inputs, ... }:

let
  channels_path = "channels/nixpkgs";
in
{
  shared-nix-settings.enable = true;

  nix = {
    # man nix.conf
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
      builders-use-substitutes = true;
    };
    gc = {
      automatic = true;
      dates = "Tue,Fri 04:00";
      persistent = true;
      options = "--delete-older-than 15d";
    };
    # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
    nixPath = [
      "nixpkgs=/etc/${channels_path}"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  environment.etc."${channels_path}".source = inputs.nixpkgs.outPath;
}
