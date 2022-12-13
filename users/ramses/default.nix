{ config, lib, pkgs, ... }:

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
    shell = pkgs.zsh;
    description = username;
    extraGroups = map (group: group_cfg.${group}.name) ([
      "keys"
      "wheel"
    ]
    ++ optional config.services.pipewire.enable "audio"
    ++ optional config.networking.networkmanager.enable "networkmanager");
    passwordFile = config.sops.secrets."${username}-user-password".path;
    openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
  };

  programs.zsh.enable = true;

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
      "ssh-extra-config" = {
        inherit sopsFile owner group mode;
      };
    };
}

