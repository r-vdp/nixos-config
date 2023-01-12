{ config, lib, pkgs, ... }:

let
  inherit (lib.hm) dag;
in
{
  options.home.settings.ssh-to-age.enable =
    lib.mkEnableOption "the ssh-to-age activation snippet";

  config = lib.mkIf config.home.settings.ssh-to-age.enable {
    # Automatically put in place the age key corresponding to our SSH key
    home.activation.ssh-to-age =
      let
        sops_dir = "${config.xdg.configHome}/sops/";
        age_dir = "${sops_dir}/age/";

        private_key_file = config.home.settings.keys.privateKeyFiles.current;
      in
      dag.entryAfter [ "writeBoundary" ] ''
        if [[ -L "${age_dir}" ]]; then
          ''${DRY_RUN_CMD} unlink ''${VERBOSE_ARG} "${age_dir}"
        else
          ''${DRY_RUN_CMD} rm --force --recursive ''${VERBOSE_ARG} "${age_dir}"
        fi
        if [[ -f "${private_key_file}" ]]; then
          real_dir="''${XDG_RUNTIME_DIR}/age"
          real_file="''${real_dir}/keys.txt"
          ''${DRY_RUN_CMD} mkdir --parents ''${VERBOSE_ARG} "${sops_dir}"
          ''${DRY_RUN_CMD} mkdir --parents ''${VERBOSE_ARG} "''${real_dir}"
          ''${DRY_RUN_CMD} ${pkgs.ssh-to-age}/bin/ssh-to-age \
            -private-key \
            -i ${private_key_file} \
            -o ''${real_file}
          ''${DRY_RUN_CMD} ln --symbolic ''${VERBOSE_ARG} ''${real_dir} "${age_dir}"
          ''${DRY_RUN_CMD} chmod --recursive u=rwX,g=,o= ''${VERBOSE_ARG} "${sops_dir}"
        fi
      '';
  };
}
