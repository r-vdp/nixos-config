{ config, lib, ... }:

with lib;

let
  inherit (lib.hm) dag;
in
{
  programs.ssh = {
    enable = true;
    compression = true;
    extraConfig = ''
      Port 22
      TCPKeepAlive yes
      PreferredAuthentications publickey,keyboard-interactive,password
      HostKeyAlgorithms -ssh-rsa
      ForwardX11 no
      StrictHostKeyChecking ask
      UpdateHostKeys yes
      GSSAPIAuthentication no
      User = ${config.home.username}
      IdentityFile ${config.home.settings.keys.privateKeyFiles.current}
      AddKeysToAgent = no
      Ciphers = aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
    '';
    matchBlocks =
      let
        needs_tmux = dag.entryBefore [ "tmux" ];
        id_ec = config.home.settings.keys.privateKeyFiles.id_ec;
      in
      {
        nixer = needs_tmux {
          host = "nixer nixer-tmux";
          hostname = "sshv6.engyandramses.xyz";
          port = 2443;
        };
        nixer-local = needs_tmux {
          host = "nixer-local nixer-local-tmux";
          hostname = "nixer.local";
        };
        sshrelay2 = needs_tmux {
          host = "sshrelay2 sshrelay2-tmux";
          hostname = "sshrelay2.ocb.msf.org";
          port = 443;
          identityFile = id_ec;
        };
        ssh-relay-proxy = {
          host = "ssh-relay-proxy";
          hostname = "sshrelay.ocb.msf.org";
          user = "tunneller";
          port = 443;
          identityFile = id_ec;
        };
        nixer-relayed = needs_tmux {
          host = "nixer-relayed nixer-relayed-tmux";
          hostname = "localhost";
          port = 6012;
          proxyJump = "ssh-relay-proxy";
          identityFile = id_ec;
        };
        rescue-iso = needs_tmux {
          host = "rescue-iso rescue-iso-tmux";
          hostname = "localhost";
          port = 8000;
          proxyJump = "ssh-relay-proxy";
          identityFile = id_ec;
          extraOptions = {
            UserKnownHostsFile = "/dev/null";
            GlobalKnownHostsFile = "/dev/null";
            StrictHostKeyChecking = "no";
          };
        };
        generic = needs_tmux {
          host = "generic generic-tmux";
          hostname = "localhost";
          proxyJump = "ssh-relay-proxy";
          identityFile = id_ec;
        };
        proxy = {
          host = "proxy";
          hostname = "sshrelay.ocb.msf.org";
          port = 443;
          identityFile = id_ec;
          dynamicForwards = [
            { port = 9443; }
          ];
          extraOptions = {
            ExitOnForwardFailure = "yes";
            RequestTTY = "false";
            SessionType = "none";
            PermitLocalCommand = "yes";
            LocalCommand = ''echo "Started tunnel at $(date)..."'';
          };
        };
        github = {
          host = "github.com";
          hostname = "ssh.github.com";
          user = "git";
          port = 443;
        };
        tmux = {
          host = "*-tmux";
          extraOptions = {
            RequestTTY = "Force";
            RemoteCommand = "tmux attach";
          };
        };
      };
  };
}

