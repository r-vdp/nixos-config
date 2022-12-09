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

  # FIXME: we are repeating modules/nix.nix here
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    fallback = true;
    warn-dirty = false;
    connect-timeout = 5;
    log-lines = 50;

    min-free = 128 * 1000 * 1000; # 128 MB
    max-free = 1000 * 1000 * 1000; # 1 GB
  };
  nixpkgs.config.allowUnfree = true;
}

