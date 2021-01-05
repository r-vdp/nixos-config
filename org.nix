{ config, lib, ... }:

with lib;
with (import ../msf_lib.nix).msf_lib.user_roles;
# user_lib is a function in user_roles which needs to be evaluated
# with the current config to obtain a set of functions to be imported
with (user_lib config);

let
  cfg = config.settings.org;
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
        nix_channel = let
          host_name = config.settings.network.host_name;
        in mkDefault (if (elem host_name cfg.early_upgrade_hosts)
                      then cfg.upgrade_url
                      else cfg.stable_url);

        users_json_path   = ./json/users.json;
        tunnels_json_path = ./json/tunnels.json;
        pub_keys_path     = ./keys;
        secretsDirectory  = "/opt/.secrets/";
      };

      maintenance.config_repos.org = mkForce {
        branch = "main";
        url = "git@github.com:R-VdP/nixos-config.git";
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
      };

      users.users = {
        ramses = globalAdmin;
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

