{ config, lib, pkgs, ... }:

{
  options.home.settings.ssh-to-age.enable =
    lib.mkEnableOption "the ssh-to-age activation snippet";

  config = lib.mkIf config.home.settings.ssh-to-age.enable {
    systemd.user.services =
      let
        mkScriptString = name: content:
          toString (pkgs.writeShellScript name content);
      in
      {
        ssh-to-age =
          let
            sops_dir = "${config.xdg.configHome}/sops";
            age_dir = "${sops_dir}/age";
            private_key_file = config.home.settings.keys.privateKeyFiles.current;

            clean = ''
              if [[ -L "${age_dir}" ]]; then
                ${lib.getBin pkgs.coreutils}/bin/unlink "${age_dir}"
              else
                ${lib.getBin pkgs.coreutils}/bin/rm --force --recursive "${age_dir}"
              fi
            '';
          in
          {
            Unit = {
              Description = ''
                Automatically put in place the age key corresponding to our SSH key
              '';
            };

            Service =
              {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = mkScriptString "ssh-to-age-start" ''
                  ${clean}
                  if [[ -f "${private_key_file}" ]]; then
                    real_dir="''${XDG_RUNTIME_DIR}/age"
                    real_file="''${real_dir}/keys.txt"
                    ${lib.getBin pkgs.coreutils}/bin/mkdir --parents "${sops_dir}"
                    ${lib.getBin pkgs.coreutils}/bin/mkdir --parents "''${real_dir}"
                    ${lib.getExe pkgs.ssh-to-age} \
                      -private-key \
                      -i ${private_key_file} \
                      -o ''${real_file}
                    ${lib.getBin pkgs.coreutils}/bin/ln --symbolic "''${real_dir}" "${age_dir}"
                    ${lib.getBin pkgs.coreutils}/bin/chmod --recursive u=rwX,g=,o= "${sops_dir}"
                  fi
                '';

                ExecStop = mkScriptString "ssh-to-age-stop" clean;
              };

            Install = {
              WantedBy = [ "default.target" ];
            };
          };
      };
  };
}
