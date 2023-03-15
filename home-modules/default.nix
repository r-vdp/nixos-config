{ inputs, config, lib, pkgs, ... }:

let
  inherit (lib.hm) dag;
in
{
  imports = import ../import-dir.nix { inherit lib; fromDir = ./.; } ++ [
    ../shared-modules
    inputs.nix-index-database.hmModules.nix-index
  ];

  options = {
    home.settings = {
      profile = lib.mkOption {
        type = with lib.types; enum (lib.attrValues config.home.settings.profileValues);
      };

      profileValues = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = {
          standalone = "standalone";
          integrated = "integrated";
        };
        readOnly = true;
      };

      keys = {
        privateKeyFiles = {
          current = lib.mkOption {
            type = lib.types.str;
          };
          id_ec = lib.mkOption {
            type = lib.types.str;
          };
        };
      };

      extraSshConfig = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = { };
      };

      isHeadless = lib.mkOption {
        type = lib.types.bool;
      };

      tmux_term = lib.mkOption {
        type = lib.types.str;
        default = "tmux-256color";
      };
    };
  };

  config = {
    home = {
      packages = with pkgs; [
        acl
        bind # For the dig command
        file
        git
        gptfdisk
        lsof
        nix-tree
        parted
        pciutils
        sops
        sshuttle
        sysfsutils
        tcptrack
      ];

      activation.extra-ssh-config =
        let
          ssh_dir = "${config.home.homeDirectory}/.ssh/";
          config_dir = "${ssh_dir}/config.d/";
          out_file = "${config_dir}/ssh-extra-config";

          mkConfigFile = source: ''
            ''${DRY_RUN_CMD} rm ''${VERBOSE_ARG} --force --recursive ${config_dir}
            ''${DRY_RUN_CMD} mkdir ''${VERBOSE_ARG} --parents ${config_dir}
            ''${DRY_RUN_CMD} ln ''${VERBOSE_ARG} --symbolic ${source} ${out_file}
            ''${DRY_RUN_CMD} chmod ''${VERBOSE_ARG} --recursive u=rwX,g=,o= ${config_dir}
          '';
        in
        dag.entryAfter [ "writeBoundary" ] (
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (_: mkConfigFile) config.home.settings.extraSshConfig)
        );
    };

    systemd.user.startServices = "sd-switch";

    # Make sure that fonts enabled through home-manager
    # are available to the system.
    fonts.fontconfig.enable = true;

    xdg.enable = true;

    programs = {
      home-manager.enable = true;
      htop.enable = true;
    };
  };
}
