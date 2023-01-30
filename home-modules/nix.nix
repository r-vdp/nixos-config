{ lib, config, ... }:

{
  options.home.settings.nixSettings = {
    enable = lib.mkEnableOption "our custom nix settings.";
  };

  config.shared-nix-settings =
    { inherit (config.home.settings.nixSettings) enable; };
}
