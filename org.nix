{ config, lib, pkgs, ... }:

with lib;

let
  sys_cfg = config.settings.system;

  globalAdmin = user_perms.admin // { enable = true; };

  user_perms =
    let
      # Admin users have shell access and belong to the wheel group
      admin = {
        enable = mkDefault false;
        sshAllowed = true;
        hasShell = true;
        canTunnel = true;
        extraGroups = [ "wheel" "docker" ];
      };
    in
    { inherit admin; };
in
{
  config = {
    settings = {
      system = {
        nix_channel = "https://nixos.org/channels/nixos-unstable";

        org = {
          # This value has an impact on global environment variables,
          # be sure that you know what you are doing before changing it!!
          env_var_prefix = "NIXOS";
          github_org = "MSF-OCB";
          iso = {
            menu_label = "NixOS rescue system";
            file_label = "nixos-rescue";
          };
        };

        users_json_path = ./json/users.json;
        keys_json_path = ./json/keys.json;
        tunnels_json_dir_path = ./json/tunnels.d;
        secrets = {
          dest_directory = "/run/.secrets/";
          src_directory = ./secrets/generated;
        };
      };

      services.traefik.acme = {
        dns_provider = "route53";
        email_address = "ramses.denorre@gmail.com";
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

      reverse_tunnel.relay_servers =
        let
          public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDsn2Dvtzm6jJyL9SJY6D1/lRwhFeWR5bQtSSQv6bZYf";
        in
        {
          sshrelay1 = {
            inherit public_key;
            addresses = [ "sshrelay1.ocb.msf.org" "185.199.180.11" ];
          };
          sshrelay2 = {
            inherit public_key;
            addresses = [ "sshrelay2.ocb.msf.org" "15.188.17.148" ];
          };
          sshrelay-za-1 = {
            inherit public_key;
            addresses = [ "sshrelay-za-1.ocb.msf.org" "13.245.67.199" ];
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
      # Lock the root user
      root = {
        hashedPassword = mkForce "!";
      };
    };
  };
}

