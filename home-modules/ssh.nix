{ config, lib, ... }:

let
  inherit (lib.hm) dag;
in
{
  programs.ssh = {
    enable = true;
    compression = true;
    serverAliveInterval = 5;
    serverAliveCountMax = 3;
    extraConfig =
      let
        commaSep = lib.concatStringsSep ",";
      in
      ''
        Port 22
        PreferredAuthentications publickey,keyboard-interactive,password
        HostKeyAlgorithms -ssh-rsa
        KexAlgorithms ${commaSep config.settings.shared.ssh.KexAlgorithms}
        Macs ${commaSep config.settings.shared.ssh.Macs}
        ForwardX11 no
        StrictHostKeyChecking accept-new
        UpdateHostKeys yes
        GSSAPIAuthentication no
        User = ${config.home.username}
        IdentityFile ${config.home.settings.keys.privateKeyFiles.current}
        AddKeysToAgent = no
        Ciphers = ${commaSep config.settings.shared.ssh.Ciphers}
      '';
    includes = [
      "config.d/*"
    ];
    matchBlocks =
      let
        needs_tmux = dag.entryBefore [ "tmux" ];
        inherit (config.home.settings.keys.privateKeyFiles) id_ec;

        with_tmux = name: ''${name} ${name}-tmux'';
      in
      {
        sshrelay2 = needs_tmux {
          host = with_tmux "sshrelay2";
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
        rescue-iso = needs_tmux {
          host = with_tmux "rescue-iso";
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
          host = with_tmux "generic";
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
            RemoteCommand = "exec tmux attach";
          };
        };
        # Separate entry without dynamic forwards to be used as a jump host.
        dev1-jumphost = {
          hostname = "dev1.numtide.com";
        };
        dev1 = needs_tmux {
          host = with_tmux "dev1";
          hostname = "dev1.numtide.com";
          dynamicForwards = [{ port = 60600; }];
        };
      };
  };
}
