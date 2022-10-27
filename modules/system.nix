{ config, lib, pkgs, nixos-channel, nixpkgs, ... }:

with lib;

let
  cfg = config.settings.system;
in

{
  options.settings.system = {
    isHeadless = mkOption {
      type = types.bool;
    };

    withExtraPythonPackages = mkOption {
      type = with types; listOf (functionTo (listOf types.package));
      default = const [ ];
    };

    nameservers = mkOption {
      type = with types; listOf str;
      default =
        let
          quad9 = "dns.quad9.net";
        in
        [
          "2620:fe::fe#${quad9}"
          "2620:fe::9#${quad9}"
          "9.9.9.9#${quad9}"
          "149.112.112.112#${quad9}"
        ];
      readOnly = true;
    };

    tmux_term = mkOption {
      type = types.str;
      default = "tmux-256color";
      readOnly = true;
    };
  };

  config = {
    environment = {
      sessionVariables = {
        XDG_CACHE_HOME = "\${HOME}/.cache";
        XDG_CONFIG_HOME = "\${HOME}/.config";
        XDG_DATA_HOME = "\${HOME}/.local/share";
        XDG_STATE_HOME = "\${HOME}/.local/state";
      };
      shellInit = ''
        if [ "''${TERM}" != "${cfg.tmux_term}" ] || [ -z "''${TMUX}" ]; then
          alias nixos-rebuild='printf "nixos-rebuild: not in tmux." 2> /dev/null'
        fi
      '';
      shellAliases = {
        nix-env = ''printf "The nix-env command has been disabled." 2> /dev/null'';
        # Have bash resolve aliases with sudo
        # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
        sudo = "sudo ";
        whereami = "curl ipinfo.io";
      };
    };

    # Populate the man-db cache so that apropos works.
    # Also needed for manpage searching using telescope in neovim.
    documentation.man.generateCaches = true;

    # Because we do not have a nix channel when building the system from a flake,
    # we need to get the sqlite DB containing the available packages and their
    # binaries from somewhere else.
    # For now we just add the nixos-channel as an input to our flake and
    # use its sqlite DB.
    programs.command-not-found = {
      enable = true;
      dbPath = "${nixos-channel}/programs.sqlite";
    };

    environment.systemPackages = with pkgs;
      [
        acl
        file
        git
        gptfdisk
        htop
        lsof
        parted
        pciutils
        sysfsutils

        (pkgs.python3.withPackages (pyPkgs:
          concatMap (withPyPkgs: withPyPkgs pyPkgs) cfg.withExtraPythonPackages)
        )
      ];

    boot = {
      loader = {
        systemd-boot.enable = true;
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = config.fileSystems."/boot".mountPoint;
        };
      };
      kernelPackages = pkgs.linuxPackages_latest;
      tmpOnTmpfs = true;
      kernel.sysctl = {
        "net.ipv6.conf.all.use_tempaddr" = "2";
      };
    };

    security = {
      sudo = {
        enable = true;
        wheelNeedsPassword = true;
      };
    };

    sops = {
      defaultSopsFile =
        ../secrets/sops/${config.networking.hostName}-secrets.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    users = {
      mutableUsers = false;
      # Disable the root user
      users.root.hashedPassword = "!";
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 40;
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
      # https://dataswamp.org/~solene/2022-07-20-nixos-flakes-command-sync-with-system.html
      registry.nixpkgs.flake = nixpkgs;
      nixPath = [
        "nixpkgs=/etc/channels/nixpkgs"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];
    };
    environment.etc."channels/nixpkgs".source = nixpkgs.outPath;

    services = {
      fwupd.enable = true;
      fstrim.enable = true;

      timesyncd = {
        enable = true;
        servers = mkDefault [
          "0.nixos.pool.ntp.org"
          "1.nixos.pool.ntp.org"
          "2.nixos.pool.ntp.org"
          "3.nixos.pool.ntp.org"
          "time.windows.com"
          "time.google.com"
        ];
      };

      resolved = {
        enable = true;
        domains = [ "~." ];
        dnssec = "false";
        extraConfig = ''
          DNS=${concatStringsSep " " cfg.nameservers}
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


    systemd = mkMerge [
      (mkIf cfg.isHeadless {
        # Given that our systems are headless, emergency mode is useless.
        # We prefer the system to attempt to continue booting so
        # that we can hopefully still access it remotely.
        enableEmergencyMode = false;

        # For more detail, see:
        #   https://0pointer.de/blog/projects/watchdog.html
        watchdog = {
          # systemd will send a signal to the hardware watchdog at half
          # the interval defined here, so every 10s.
          # If the hardware watchdog does not get a signal for 20s,
          # it will forcefully reboot the system.
          runtimeTime = "20s";
          # Forcefully reboot if the final stage of the reboot
          # hangs without progress for more than 30s.
          # For more info, see:
          #   https://utcc.utoronto.ca/~cks/space/blog/linux/SystemdShutdownWatchdog
          rebootTime = "30s";
        };

        sleep.extraConfig = ''
          AllowSuspend=no
          AllowHibernation=no
        '';
      })
      # TODO
      (mkIf false {
        services.nixos-upgrade =
          let
            runtimeDir = "nixos-upgrade";
            github_key_path = "/run/${runtimeDir}/key";
          in
          {
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
      })
    ];

    hardware = {
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    };

    nixpkgs.config.allowUnfree = true;
  };
}

