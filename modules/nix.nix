{ nixpkgs, ... }:

let
  channels_path = "channels/nixpkgs";
in
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "Tue 12:00";
      options = "--delete-older-than 30d";
    };
    # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
    registry.nixpkgs.flake = nixpkgs;
    nixPath = [
      "nixpkgs=/etc/${channels_path}"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  environment.etc."${channels_path}".source = nixpkgs.outPath;
}

