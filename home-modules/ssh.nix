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
      IdentityFile ${config.home.settings.keys.privateKeyFile}
      AddKeysToAgent = no
      Ciphers = aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
    '';
    matchBlocks = {
      nixer = dag.entryBefore [ "tmux" ] {
        host = "nixer nixer-tmux";
        hostname = "sshv6.engyandramses.xyz";
        port = 2443;
      };
      nixer-local = dag.entryBefore [ "tmux" ] {
        host = "nixer-local nixer-local-tmux";
        hostname = "nixer.local";
      };
      nixer-relayed = dag.entryBefore [ "tmux" ] {
        host = "nixer-relayed nixer-relayed-tmux";
        hostname = "localhost";
        port = 6012;
        proxyJump = "ssh-relay-proxy";
      };
      rescue-iso = dag.entryBefore [ "tmux" ] {
        host = "rescue-iso rescue-iso-tmux";
        hostname = "localhost";
        port = 8000;
        proxyJump = "ssh-relay-proxy";
        extraOptions = {
          UserKnownHostsFile = "/dev/null";
          GlobalKnownHostsFile = "/dev/null";
          StrictHostKeyChecking = "no";
        };
      };
      ssh-relay-proxy = {
        host = "ssh-relay-proxy";
        hostname = "sshrelay.ocb.msf.org";
        user = "tunneller";
        port = 443;
      };
      generic = dag.entryBefore [ "tmux" ] {
        host = "generic generic-tmux";
        hostname = "localhost";
        proxyJump = "ssh-relay-proxy";
      };
      proxy = {
        host = "proxy";
        hostname = "sshrelay.ocb.msf.org";
        port = 443;
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

