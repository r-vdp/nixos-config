{ osConfig, config, lib, pkgs, nix-index-database, ... }:

with lib;

{
  imports = import ../import-dir.nix { inherit lib; fromDir = ./.; };

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

      packages = with pkgs; [
        acl
        bind # For the dig command
        file
        git
        gptfdisk
        lsof
        nixos-option
        parted
        pciutils
        sops
        sysfsutils
      ];
    };

    xdg.enable = true;
    programs = {
      home-manager.enable = true;
      htop.enable = true;
    };
  };
}

