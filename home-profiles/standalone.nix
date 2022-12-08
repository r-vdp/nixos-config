# Config used for standalone home-manager profiles, not integrated into NixOS.
{ inputs, config, ... }: {
  home = {
    inherit (inputs) username;
    homeDirectory = "/home/${config.home.username}";
    settings = {
      isHeadless = true;
      keys.privateKeyFiles =
        let
          sshDir = "${config.home.homeDirectory}/.ssh/";
        in
        {
          current = "${sshDir}/id_ed25519";
          id_ec = "${sshDir}/id_ec";
        };
    };
    stateVersion = "22.05";
  };
}

