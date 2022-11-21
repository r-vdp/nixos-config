{ osConfig, config, lib, pkgs, nix-index-database, ... }:

with lib;

{
  imports = [
    ./firefox.nix
    ./git.nix
    ./nix-index.nix
    ./ssh.nix
    ./ssh-to-age.nix
    ./tmux.nix
  ];

  options = {
    home.settings = {
      keys = {
        privateKeyFile = mkOption {
          type = types.str;
        };

        publicKey = mkOption {
          type = types.str;
        };
      };
    };
  };

  config = {
    home = {
      inherit (osConfig.system) stateVersion;
      homeDirectory = mkDefault osConfig.users.users.${config.home.username}.home;
    };

    xdg.enable = true;
    programs.home-manager.enable = true;
  };
}

