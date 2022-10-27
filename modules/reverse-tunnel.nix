{ config, pkgs, lib, ... }:

with lib;

let
  inherit (config.lib) ext_lib;

  cfg = config.settings.reverse_tunnel;
  sys_cfg = config.settings.system;

  relayServerOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
      };

      addresses = mkOption {
        type = with types; listOf str;
      };

      public_key = mkOption {
        type = ext_lib.pub_key_type;
      };

      ports = mkOption {
        type = with types; listOf port;
        default = [ 22 80 443 ];
      };
    };

    config = {
      name = mkDefault name;
    };
  };
in
{
  options = {
    settings.reverse_tunnel = {
      enable = mkEnableOption "the reverse tunnel services";

      remote_forward_port = mkOption {
        type = types.port;
        description = "The port used for this server on the relay servers.";
      };

      relay_servers = mkOption {
        type = with types; attrsOf (submodule relayServerOpts);
      };
    };
  };

  config = mkIf cfg.enable {
    users = {
      users.tunnel = {
        isSystemUser = true;
        group = config.users.groups.tunnel.name;
      };
      groups.tunnel = { };
    };

    sops.secrets = {
      tunnel-ssh-priv-key = { };
    };

    # This line is very important, it ensures that the remote hosts can
    # set up their reverse tunnels without any issues with host keys
    programs.ssh.knownHosts =
      mapAttrs
        (_: conf: {
          hostNames = conf.addresses;
          publicKey = conf.public_key;
        })
        cfg.relay_servers;

    systemd.services =
      let
        make_tunnel_service = relay: {
          inherit (cfg) enable;
          description = "AutoSSH reverse tunnel service";
          wants = [ "network.target" ];
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            AUTOSSH_GATETIME = "0";
            AUTOSSH_PORT = "0";
            AUTOSSH_MAXSTART = "10";
          };
          serviceConfig = {
            User = config.users.users.tunnel.name;
            SupplementaryGroups = [ config.users.groups.keys.name ];
            Type = "simple";
            Restart = "always";
            RestartSec = "10min";
          };
          script = ''
            for host in ${concatStringsSep " " relay.addresses}; do
              for port in ${concatMapStringsSep " " toString relay.ports}; do
                echo "Attempting to connect to ''${host} on port ''${port}"
                ${pkgs.autossh}/bin/autossh \
                  -T -N \
                  -o "ExitOnForwardFailure=yes" \
                  -o "ServerAliveInterval=10" \
                  -o "ServerAliveCountMax=5" \
                  -o "ConnectTimeout=360" \
                  -o "UpdateHostKeys=no" \
                  -o "StrictHostKeyChecking=yes" \
                  -o "UserKnownHostsFile=/dev/null" \
                  -o "IdentitiesOnly=yes" \
                  -o "Compression=yes" \
                  -o "ControlMaster=no" \
                  -R "${toString cfg.remote_forward_port}:localhost:22" \
                  -i ${config.sops.secrets.tunnel-ssh-priv-key.path} \
                  -p ''${port} \
                  -l ${config.users.users.tunnel.name} \
                  ''${host}
              done
            done
          '';
        };

        make_tunnel_services =
          mapAttrs' (_: relay: nameValuePair
            "autossh-reverse-tunnel-${relay.name}"
            (make_tunnel_service relay));
      in
      make_tunnel_services cfg.relay_servers;
  };
}

