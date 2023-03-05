# Config used when home-manager is integrated into a NixOS system.
# We can access the NixOS system config through the osConfig input argument.
{ osConfig, config, lib, ... }:
let
  inherit (osConfig.sops) secrets;
in
{
  home = {
    inherit (osConfig.system) stateVersion;

    homeDirectory =
      lib.mkDefault osConfig.users.users.${config.home.username}.home;

    settings = {
      inherit (osConfig.settings.system) isHeadless tmux_term;

      profile = config.home.settings.profileValues.integrated;

      atuin.keyPath = secrets."${config.home.username}-atuin-encryption-key".path;

      keys = {
        privateKeyFiles = {
          id_ec = secrets."${config.home.username}-ssh-priv-key".path;
          current = secrets."${config.home.username}-2-ssh-priv-key".path;
        };
      };
      ssh-to-age.enable = true;

      extraSshConfig = {
        extra-ssh-config = osConfig.sops.secrets."ssh-extra-config".path;
      };
    };
  };
}
