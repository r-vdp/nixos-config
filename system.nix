{ config, lib, pkgs, ... }:

with lib;

{
  config = {

    environment.sessionVariables = {
      XDG_CACHE_HOME = "\${HOME}/.cache";
      XDG_CONFIG_HOME = "\${HOME}/.config";
      XDG_DATA_HOME = "\${HOME}/.local/share";
      XDG_STATE_HOME = "\${HOME}/.local/state";
    };

    environment.systemPackages = with pkgs; [
      (haskellPackages.ghcWithHoogle (hsPkgs: with hsPkgs; [
        stack
      ]))
      haskell-language-server
      elmPackages.elm
      elmPackages.elm-language-server
      elmPackages.elm-format
      elmPackages.elm-review
      elm2nix
      nixos-option
      git
      htop
    ];

    boot.kernelPackages = pkgs.linuxPackages_latest;

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 40;
    };

    programs = {
      # Only safe on single-user machines
      ssh.startAgent = mkForce true;

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
            set-option -g default-terminal "${tmux_term}"
            set-option -sa terminal-overrides ',xterm-256color:RGB'
          '';
        };
    };

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
      };
      gc = {
        automatic = true;
        dates = "Tue 12:00";
        options = "--delete-older-than 30d";
      };
    };

    services =
      {
        fwupd.enable = true;

        resolved =
          let
            nameservers = [
              "2620:fe::fe#dns.quad9.net"
              "2620:fe::9#dns.quad9.net"
              "9.9.9.9#dns.quad9.net"
              "149.112.112.112#dns.quad9.net"
            ];
          in
          {
            enable = true;
            domains = [ "~." ];
            dnssec = "false";
            extraConfig = ''
              DNS=${concatStringsSep " " nameservers}
              DNSOverTLS=true
            '';
          };
      };

    system.autoUpgrade = {
      enable = false;
      flake = "git+ssh://github.com/R-VdP/nixos-config";
      flags = [
        "--refresh"
        # We pull a remote repo into the nix store,
        # so we cannot write the lock file.
        "--no-write-lock-file"
        # TODO: fix. Can we avoid needing to load the key from outside?
        #            How would we bootstrap the decryption of the secrets then?
        # We need to load the server's key from the filesystem, which is impure.
        "--impure"
      ];
      dates = "Fri 18:00";
      allowReboot = true;
      rebootWindow = mkForce { lower = "10:00"; upper = "21:00"; };
    };

    systemd.services.nixos-upgrade =
      let
        runtimeDir = "nixos-upgrade";
        github_key_path = "/run/${runtimeDir}/key";
      in
      mkIf false {
        serviceConfig = {
          RuntimeDirectoryMode = "0700";
          RuntimeDirectory = runtimeDir;
        };
        preStart = ''
          install \
            --mode=0600 \
            "${config.settings.system.secrets.dest_directory}/nixos-config-deploy-key" \
            "${github_key_path}"
        '';
        environment = {
          GIT_SSH_COMMAND = concatStringsSep " " [
            "${pkgs.openssh}/bin/ssh"
            "-F /etc/ssh/ssh_config"
            "-i ${github_key_path}"
            "-o IdentitiesOnly=yes"
            "-o StrictHostKeyChecking=yes"
          ];
        };
      };

    users.users = mkIf false {
      # Lock the root user
      root = {
        hashedPassword = mkForce "!";
      };
    };
  };
}

