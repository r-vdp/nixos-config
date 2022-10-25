{ osConfig, config, lib, pkgs, ... }:

let
  inherit (lib.hm) dag;

  privKeyFile = osConfig.sops.secrets.ssh-priv-key.path;
  pubKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDyV+zVbtGMdiRwSBnnkcHtZAe2F/zmBUDUqMY4Sr+K";
  osUser = osConfig.users.users.ramses;
in
{
  home = {
    inherit (osConfig.system) stateVersion;
    username = osUser.name;
    homeDirectory = osUser.home;

    packages = with pkgs; [
      authy
      dropbox
      htop
      keepassxc
      nixos-option
      pcloud
      signal-desktop
      slack
      sops
      vlc

      elmPackages.elm
      elm2nix
      (haskellPackages.ghcWithHoogle (hsPkgs: with hsPkgs; [
        stack
      ]))
    ];

    activation = {
      # Automatically put in place the age key corresponding to our SSH key
      ssh-to-age =
        let
          out_dir = "${config.home.homeDirectory}/.config/sops/age/";
          out_file = "${out_dir}/keys.txt";
        in
        dag.entryAfter [ "writeBoundary" ] ''
          ''${DRY_RUN_CMD} rm --force ''${VERBOSE_ARG} ${out_file}
          ''${DRY_RUN_CMD} mkdir --parents ''${VERBOSE_ARG} ${out_dir}
          ''${DRY_RUN_CMD} ${pkgs.ssh-to-age}/bin/ssh-to-age \
            -private-key \
            -i ${privKeyFile} \
            -o ${out_file}
        '';
    };
  };

  programs = {
    home-manager.enable = true;

    firefox = {
      enable = true;
      package = pkgs.firefox-wayland;
      profiles.ramses = {
        isDefault = true;
        settings =
          let
            quad9 = "https://quad9.net/dns-query";
          in
          {
            "browser.ctrlTab.sortByRecentlyUsed" = true;
            "browser.startup.page" = 3;
            "browser.search.region" = "BE";
            "browser.tabs.warnOnClose" = true;
            "dom.security.https_only_mode" = true;
            "network.proxy.type" = 0;
            "network.trr.custom_uri" = quad9;
            "network.trr.default_provider_uri" = quad9;
            "network.trr.uri" = quad9;
            "network.trr.mode" = 2;
            "network.trr.wait-for-portal" = true;
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
        signingKey = privKeyFile;
        inherit pubKey;
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
                  ${userEmail} ${pubKey}
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
        IdentityFile ${privKeyFile}
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

