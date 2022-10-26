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
  };

  home-manager.users.${username} = import ../users/${username}-home.nix;

  sops.secrets =
    let
      sopsFile = ../secrets/sops/${username}-secrets.yaml;
    in
    {
      "${username}-ssh-priv-key" = {
        inherit sopsFile;
        mode = "0600";
        owner = user_cfg.${username}.name;
        group = user_cfg.${username}.group;
      };
      "${username}-user-password" = {
        inherit sopsFile;
        neededForUsers = true;
      };
    };
}

