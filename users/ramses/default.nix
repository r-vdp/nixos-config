{ config, lib, nix-index-database, ... }:

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

  home-manager = {
    # Extra arguments to pass to home-manager modules
    extraSpecialArgs = { inherit nix-index-database; };
    users.${username} = import ./home.nix { inherit username; };
  };

  sops.secrets =
    let
      sopsFile = ../../secrets/${username}-secrets.yaml;
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
      "${username}-keepass-keyfile" = {
        inherit sopsFile;
        mode = "0600";
        owner = user_cfg.${username}.name;
        group = user_cfg.${username}.group;
      };
    };
}

