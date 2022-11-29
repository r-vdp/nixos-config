{ config, lib, ... }:

with lib;

let
  group_cfg = config.users.groups;
  user_cfg = config.users.users;
  username = "ramses";
in

{
  users.users.${username} = {
    uid = 1000;
    isNormalUser = true;
    description = username;
    extraGroups = map (group: group_cfg.${group}.name) ([
      "keys"
      "wheel"
    ]
    ++ optional config.services.pipewire.enable "audio"
    ++ optional config.networking.networkmanager.enable "networkmanager");
    passwordFile = config.sops.secrets."${username}-user-password".path;
    openssh.authorizedKeys.keys = [
      ("ssh-ed25519 " +
        "AAAAC3NzaC1lZDI1NTE5AAAAIIXvTazOvC1ajjkN7Iq+qHrofOp8iXBI7TMwwHnsrm58")
    ];
  };

  home-manager = {
    users.${username} = {
      imports = [ ./home.nix ];
      home = { inherit username; };
    };
  };

  sops.secrets =
    let
      sopsFile = ../../secrets/${username}-secrets.yaml;
      owner = user_cfg.${username}.name;
      group = user_cfg.${username}.group;
      mode = "0600";
    in
    {
      "${username}-ssh-priv-key" = {
        inherit sopsFile owner group mode;
      };
      "${username}-2-ssh-priv-key" = {
        inherit sopsFile owner group mode;
      };
      "${username}-user-password" = {
        inherit sopsFile;
        neededForUsers = true;
      };
      "${username}-keepass-keyfile" = {
        inherit sopsFile owner group mode;
      };
    };
}

