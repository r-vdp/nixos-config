{ config, pkgs, lib, ... }:

let
  inherit (config.lib) ext_lib;

  cfg = config.settings.reverse_tunnel;

  relayServerOpts = { name, ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
      };

      addresses = lib.mkOption {
        type = with lib.types; listOf str;
      };

      public_key = lib.mkOption {
        type = ext_lib.pub_key_type;
      };

      ports = lib.mkOption {
        type = with lib.types; listOf port;
        default = [ 22 80 443 ];
      };
    };

    config = {
      name = lib.mkDefault name;
    };
  };
in
{
  options = {
    settings.reverse_tunnel = {
      enable = lib.mkEnableOption "the reverse tunnel services";

      remote_forward_port = lib.mkOption {
        type = lib.types.port;
        description = "The port used for this server on the relay servers.";
      };

      relay_servers = lib.mkOption {
        type = with lib.types; attrsOf (submodule relayServerOpts);
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
      lib.mapAttrs
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
            for host in ${lib.concatStringsSep " " relay.addresses}; do
              for port in ${lib.concatMapStringsSep " " toString relay.ports}; do
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
          lib.mapAttrs' (_: relay: lib.nameValuePair
            "autossh-reverse-tunnel-${relay.name}"
            (make_tunnel_service relay));
      in
      make_tunnel_services cfg.relay_servers;
  };
}
