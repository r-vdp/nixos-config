{ config, lib, pkgs, ... }:

let
  inherit (lib.hm) dag;
in
{
  # Automatically put in place the age key corresponding to our SSH key
  home.activation.ssh-to-age =
    let
      sops_dir = "${config.xdg.configHome}/sops/";
      age_dir = "${sops_dir}/age/";
      out_file = "${age_dir}/keys.txt";
    in
    dag.entryAfter [ "writeBoundary" ] ''
      ''${DRY_RUN_CMD} rm --force ''${VERBOSE_ARG} ${out_file}
      ''${DRY_RUN_CMD} mkdir --parents ''${VERBOSE_ARG} ${age_dir}
      ''${DRY_RUN_CMD} ${pkgs.ssh-to-age}/bin/ssh-to-age \
        -private-key \
        -i ${config.home.settings.keys.privateKeyFiles.current} \
        -o ${out_file}
      ''${DRY_RUN_CMD} chmod --recursive u=rwX,g=,o= ''${VERBOSE_ARG} ${sops_dir}
    '';
}

