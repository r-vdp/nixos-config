# Config used for standalone home-manager profiles, not integrated into NixOS.
{ lib, inputs, config, pkgs, ... }:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    settings = {
      nixSettings.enable = lib.mkDefault true;

      keys.privateKeyFiles =
        let
          sshDir = "${config.home.homeDirectory}/.ssh/";
        in
        lib.mkDefault {
          current = "${sshDir}/id_ed25519";
          id_ec = "${sshDir}/id_ec";
        };
    };
  };
}
