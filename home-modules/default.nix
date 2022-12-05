{ osConfig, config, lib, pkgs, ... }:

with lib;

{
  imports = import ../import-dir.nix { inherit lib; fromDir = ./.; };

  options = {
    home.settings = {
      keys = {
        privateKeyFiles = mkOption {
          type = with types; attrsOf str;
        };
      };

      isHeadless = mkOption {
        type = types.bool;
        default = osConfig.settings.system.isHeadless;
      };

      tmux_term = mkOption {
        type = types.str;
        default = osConfig.settings.system.tmux_term;
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
        parted
        pciutils
        sops
        sshuttle
        sysfsutils
        tcptrack
      ];
    };

    xdg.enable = true;
    programs = {
      home-manager.enable = true;
      htop.enable = true;
    };
  };
}

