{ lib, config, pkgs, ... }:

{
  options.home.settings.nix = {
    enable = lib.mkEnableOption "the home-module to manage nix settings.";
  };

  config = lib.mkIf config.home.settings.nix.enable {
    # FIXME: we are repeating modules/nix.nix here
    nix = {
      package = pkgs.nix;
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        fallback = true;
        warn-dirty = false;
        connect-timeout = 5;
        log-lines = 50;

        min-free = 128 * 1000 * 1000; # 128 MB
        max-free = 1000 * 1000 * 1000; # 1 GB
      };
    };
    nixpkgs.config.allowUnfree = true;
  };
}

