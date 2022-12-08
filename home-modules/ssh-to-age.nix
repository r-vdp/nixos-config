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
        out_file = "${age_dir}/keys.txt";

        private_key_file = config.home.settings.keys.privateKeyFiles.current;
      in
      dag.entryAfter [ "writeBoundary" ] ''
        ''${DRY_RUN_CMD} rm --force ''${VERBOSE_ARG} ${out_file}
        if [[ -f "${private_key_file}" ]]; then
          ''${DRY_RUN_CMD} mkdir --parents ''${VERBOSE_ARG} ${age_dir}
          ''${DRY_RUN_CMD} ${pkgs.ssh-to-age}/bin/ssh-to-age \
            -private-key \
            -i ${private_key_file} \
            -o ${out_file}
          ''${DRY_RUN_CMD} chmod --recursive u=rwX,g=,o= ''${VERBOSE_ARG} ${sops_dir}
        fi
      '';
  };
}

