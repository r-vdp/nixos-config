{ inputs, ... }:

let
  channels_path = "channels/nixpkgs";
in
{
  nix = {
    # man nix.conf
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" "@wheel" ];
      fallback = true;
      warn-dirty = false;
      connect-timeout = 5;
      log-lines = 50;

      min-free = 128 * 1000 * 1000; # 128 MB
      max-free = 1000 * 1000 * 1000; # 1 GB

      builders-use-substitutes = true;
    };
    gc = {
      automatic = true;
      dates = "Tue,Fri 12:00";
      options = "--delete-older-than 15d";
    };
    # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [
      "nixpkgs=/etc/${channels_path}"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  environment.etc."${channels_path}".source = inputs.nixpkgs.outPath;
}
