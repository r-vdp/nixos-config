{ config, lib, pkgs, ... }:

let
  group_cfg = config.users.groups;
  user_cfg = config.users.users;
  username = "ramses";
in

{
  users.users.${username} = {
    uid = 1000;
    isNormalUser = true;
    shell = pkgs.fish;
    description = username;
    extraGroups = map (group: group_cfg.${group}.name) ([
      "keys"
      "wheel"
    ]
    ++ lib.optional config.services.pipewire.enable "audio"
    ++ lib.optional config.networking.networkmanager.enable "networkmanager");
    passwordFile = config.sops.secrets."${username}-user-password".path;
    openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];
  };

  system.activationScripts."${username}-volatile-cache" = lib.stringAfter [ "users" "groups" ] ''
    if [ ! -d /vol/volatile/${username}/cache ]; then
      install -m 0700 -d /vol/volatile/${username}
      install -m 0700 -d /vol/volatile/${username}/cache
      chown --recursive ${username}:${group_cfg.users.name} /vol/volatile/${username}/cache
    fi
  '';

  home-manager = {
    users.${username} = {
      imports = [ ./home.nix ];
      home = { inherit username; };
    };
  };

  sops.secrets =
    let
      sopsFile = lib.path.append ../../secrets "${username}-secrets.yaml";
      owner = user_cfg.${username}.name;
      inherit (user_cfg.${username}) group;
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
      "${username}-atuin-encryption-key" = {
        inherit sopsFile owner group mode;
      };
      "${username}-keepass-keyfile" = {
        inherit sopsFile owner group mode;
      };
      "ssh-extra-config" = {
        inherit sopsFile owner group mode;
      };
      "harvest-env" = {
        inherit sopsFile owner group mode;
      };
    };
}
