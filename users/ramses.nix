{ config, lib, pkgs, ... }:

{
  home = {
    username = "ramses";
    homeDirectory = "/home/" + config.home.username;
    stateVersion = "22.05";

    packages = with pkgs; [
      keepassxc
      signal-desktop
      slack
      dropbox
      pcloud
      authy
      vlc
    ];
  };

  programs = {
    home-manager.enable = true;

    firefox = {
      enable = true;
      package = pkgs.firefox-wayland;
      profiles.ramses = {
        isDefault = true;
        settings = {
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.startup.page" = 3;
          "browser.search.region" = "BE";
          "browser.tabs.warnOnClose" = true;
          "dom.security.https_only_mode" = true;
          "network.proxy.type" = 0;
          "network.trr.custom_uri" = "https://quad9.net/dns-query";
          "network.trr.default_provider_uri" = "https://quad9.net/dns-query";
          "network.trr.mode" = 2;
          "privacy.donottrackheader.enabled" = true;
          "spellchecker.dictionary" = "en-GB";
          # https://wiki.archlinux.org/title/Firefox#Hardware_video_acceleration
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
        };
        search = {
          default = "DuckDuckGo";
          force = true;
          engines =
            let
              nixos-icon =
                "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            in
            {
              "NixOS Packages" = {
                urls = [{
                  template = "https://search.nixos.org/packages";
                  params = [
                    { name = "type"; value = "packages"; }
                    { name = "channel"; value = "unstable"; }
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = nixos-icon;
                definedAliases = [ "@nixos-packages" "@np" ];
              };
              "NixOS Options" = {
                urls = [{
                  template = "https://search.nixos.org/options";
                  params = [
                    { name = "type"; value = "options"; }
                    { name = "channel"; value = "unstable"; }
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = nixos-icon;
                definedAliases = [ "@nixos-options" "@no" ];
              };
            };
        };
      };
    };

    git =
      let
        userEmail = "141248+R-VdP@users.noreply.github.com";
        signingKey = "${config.home.homeDirectory}/.ssh/id_ec";
      in
      {
        enable = true;
        userName = "R-VdP";
        inherit userEmail;
        extraConfig = {
          core = { };
          gpg = {
            format = "ssh";
            ssh.allowedSignersFile =
              let
                signers = ''
                  ${userEmail} ${signingKey}
                '';
              in
              ''${pkgs.writeText "git-allowed-signers" signers}'';
          };
          user = { inherit signingKey; };
          commit.gpgsign = true;
          tag.gpgsign = true;
        };
      };

    ssh = {
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
        IdentityFile ${config.home.homeDirectory}/.ssh/id_ec
        AddKeysToAgent = no
        Ciphers = aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
      '';
      matchBlocks = {
        nixer = lib.hm.dag.entryBefore [ "tmux" ] {
          host = "nixer nixer-tmux";
          hostname = "sshv6.engyandramses.xyz";
          port = 2443;
        };
        nixer-local = lib.hm.dag.entryBefore [ "tmux" ] {
          host = "nixer-local nixer-local-tmux";
          hostname = "nixer.local";
        };
        nixer-relayed = lib.hm.dag.entryBefore [ "tmux" ] {
          host = "nixer-relayed nixer-relayed-tmux";
          hostname = "localhost";
          port = 6012;
          proxyJump = "ssh-relay-proxy";
        };
        rescue-iso = lib.hm.dag.entryBefore [ "tmux" ] {
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
        generic = lib.hm.dag.entryBefore [ "tmux" ] {
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

    tmux =
      let
        tmux_term = "tmux-256color";
      in
      {
        enable = true;
        newSession = true;
        clock24 = true;
        historyLimit = 10000;
        escapeTime = 250;
        terminal = tmux_term;
        keyMode = "vi";
        extraConfig = ''
          set -g mouse on
          set-option -g focus-events on
          set-option -sa terminal-overrides ',xterm-256color:RGB'
        '';
      };
  };
}

