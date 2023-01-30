# NOTE: This module is used by both NixOS and home-manager, so we need to be
# careful to maintain compatibility with both.
{ lib, inputs, config, ... }:

{
  options = {
    shared-nix-settings.enable = lib.mkEnableOption "the shared nix settings.";
  };

  config.nix = lib.mkIf config.shared-nix-settings.enable {
    # man nix.conf
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      fallback = true;
      warn-dirty = false;
      connect-timeout = 5;
      log-lines = 50;

      min-free = 128 * 1000 * 1000; # 128 MB
      max-free = 1000 * 1000 * 1000; # 1 GB

      builders-use-substitutes = true;
    };
    # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
    registry.nixpkgs.flake = inputs.nixpkgs;
  };
}
