{ config, lib, ... }:

with lib;

let
  cfg     = config.settings.org;
  sys_cfg = config.settings.system;

  globalAdmin = user_perms.admin // { enable = true; };

  user_perms = let

    # Admin users have shell access and belong to the wheel group
    admin = {
      enable      = mkDefault false;
      sshAllowed  = true;
      hasShell    = true;
      canTunnel   = true;
      extraGroups = [ "wheel" "docker" ];
    };
  in {
    inherit admin;
  };
in

{
  options.settings.org = {
    stable_version = mkOption {
      type = types.str;
      default = "20.09";
      readOnly = true;
      description = ''
        See the stable_domain option.
      '';
    };

    stable_domain = mkOption {
      type = types.str;
      default = "nix-channel-redirect.ocb.msf.org";
      readOnly = true;
      description = ''
        Domain redirecting to the current NixOS stable channel that we use.
        After testing a new NixOS release, we can update the channel that this
        domain is redirecting to.
        The channel that is being redirected to, is defined by the stable_version
        option in this module.
      '';
    };

    stable_url = mkOption {
      type = types.str;
      default = "https://${cfg.stable_domain}";
      readOnly = true;
      description = ''
        See the stable_domain option.
      '';
    };

    upgrade_version = mkOption {
      type = types.str;
      default = "20.09";
      readOnly = true;
      description = ''
        See the upgrade_domain option.
      '';
    };

    upgrade_domain = mkOption {
      type = types.str;
      default = "early-upgrade.nix-channel-redirect.ocb.msf.org";
      readOnly = true;
      description = ''
        Domain used to redirect to the channel of a newly released NixOS version.
        This is used in conjunction with the early_upgrade_hosts option in this
        module to test a new release on a pre-defined set of hosts before doing
        a general rollout.
        The channel that is being redirected to, is defined by the upgrade_version
        option in this module.
      '';
    };

    upgrade_url = mkOption {
      type = types.str;
      default = "https://${cfg.upgrade_domain}";
      readOnly = true;
      description = ''
        See the upgrade_domain option.
      '';
    };

    early_upgrade_hosts = mkOption {
      type = with types; listOf str;
      description = ''
        See the upgrade_domain option.
      '';
      default = [];
    };
  };

  config = {
    settings = {
      system = {
        nix_channel = cfg.upgrade_url;

        org = {
          # This value has an impact on global environment variables,
          # be sure that you know what you are doing before changing it!!
          env_var_prefix = "NIXOS";
          github_org     = "MSF-OCB";
          iso = {
            menu_label = "NixOS rescue system";
            file_label = "nixos-rescue";
          };
        };

        users_json_path       = ./json/users.json;
        keys_json_path        = ./json/keys.json;
        tunnels_json_dir_path = ./json/tunnels.d;
        secrets = {
          dest_directory = "/run/.secrets/";
          old_dest_directories = [ "/opt/.secrets" ];
          src_directory = ./secrets/generated;
        };
      };

      services.traefik = {
        pilot_token = "d553f62e-ced5-40e5-ab7f-20f0efc87e5f";
        acme = {
          dns_provider = "route53";
          email_address = "ramses.denorre@gmail.com";
        };
      };

      maintenance.config_repos = {
        main = {
          branch = "master";
          url = sys_cfg.org.repo_to_url "NixOS";
        };
        org = {
          branch = "main";
          url = ''git@github.com:R-VdP/nixos-config.git'';
        };
      };

      reverse_tunnel.relay_servers = let
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDsn2Dvtzm6jJyL9SJY6D1/lRwhFeWR5bQtSSQv6bZYf";
      in {
        sshrelay1 = {
          inherit public_key;
          addresses  = [ "sshrelay1.ocb.msf.org" "185.199.180.11" ];
        };
        sshrelay2 = {
          inherit public_key;
          addresses  = [ "sshrelay2.ocb.msf.org" "15.188.17.148"  ];
        };
        sshrelay-za-1 = {
          inherit public_key;
          addresses  = [ "sshrelay-za-1.ocb.msf.org" "13.245.67.199"  ];
        };
      };

      users = {
        available_permission_profiles = user_perms;
        users = {
          ramses = globalAdmin;
        };
      };
    };
    users.users = {
      # Only user with a password, but not usable via SSH.
      # To be used for console access in case of emergencies.
      local-admin = {
        isNormalUser = true;
        extraGroups  = [ "wheel" ];
        openssh.authorizedKeys.keyFiles = mkForce [];
        # nix-shell --packages python3 \
        #           --command "python3 -c 'import crypt,getpass; \
        #                                  print(crypt.crypt(getpass.getpass(), \
        #                                                    crypt.mksalt(crypt.METHOD_SHA512)))'"
        hashedPassword = mkDefault
          ''$6$VB1Kj0dbHNuvRl24$9YAgZYFHyk6Mr1xseoZGVmVjBr/FeYQ/VQZCNT7ulvyotzxlGhPTAANtA3J3BUEr4lzDf08IxN2C80vi7/CHv0'';
      };

      # Lock the root user
      root = {
        hashedPassword = mkForce "!";
      };
    };
  };
}

