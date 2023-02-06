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

  services.mullvad-vpn.enable = true;
  systemd.services.mullvad-daemon.restartTriggers = [
    config.environment.etc."mullvad-vpn/settings.json".source
  ];

  environment.etc."mullvad-vpn/settings.json" = {
    mode = "0400";
    user = "root";
    group = "root";
    text = lib.generators.toJSON { } {
      relay_settings = {
        normal = {
          location = {
            only = {
              country = "be";
            };
          };
          providers = "any";
          ownership = "any";
          tunnel_protocol = {
            only = "wireguard";
          };
          wireguard_constraints = {
            port = "any";
            ip_version = "any";
            use_multihop = false;
            entry_location = {
              only = {
                country = "be";
              };
            };
          };
          openvpn_constraints = {
            port = "any";
          };
        };
      };
      bridge_settings = {
        normal = {
          location = "any";
          providers = "any";
          ownership = "any";
        };
      };
      obfuscation_settings = {
        selected_obfuscation = "off";
        udp2tcp = {
          port = "any";
        };
      };
      bridge_state = "auto";
      allow_lan = false;
      block_when_disconnected = false;
      auto_connect = false;
      tunnel_options = {
        openvpn = {
          mssfix = null;
        };
        wireguard = {
          mtu = null;
          use_pq_safe_psk = true;
          rotation_interval = null;
        };
        generic = {
          enable_ipv6 = true;
        };
        dns_options = {
          state = "custom";
          default_options = {
            block_ads = true;
            block_trackers = true;
            block_malware = true;
            block_adult_content = false;
            block_gambling = false;
          };
          custom_options = {
            addresses = [
              "2620:fe::11"
              "2620:fe::fe:11"
            ];
          };
        };
      };
      show_beta_releases = false;
      wg_migration_rand_num = 0.302761;
      settings_version = 6;
    };
  };

  home-manager = {
    users.${username} = {
      imports = [ ./home.nix ];
      home = { inherit username; };
    };
  };

  sops.secrets =
    let
      sopsFile = ../../secrets + "/${username}-secrets.yaml";
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
