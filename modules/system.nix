{ config, lib, pkgs, nixpkgs, nix-index-database, ... }:

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
      type = with types; listOf (functionTo (listOf package));
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
    # Populate the man-db cache so that apropos works.
    # Also needed for manpage searching using telescope in neovim.
    documentation.man.generateCaches = true;

    # We use nix-index instead, setup with home-manager
    programs.command-not-found.enable = false;

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
        ../secrets/${config.networking.hostName}-secrets.yaml;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      secrets = {
        nixos-config-deploy-key = {
          sopsFile = ../secrets/github-secrets.yaml;
        };
      };
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
      enable = true;
      flake = "git+ssh://github.com/R-VdP/nixos-config";
      flags = [
        "--refresh"
        # We pull a remote repo into the nix store,
        # so we cannot write the lock file.
        "--no-write-lock-file"
      ];
      dates = "Fri 20:00";
      allowReboot = cfg.isHeadless;
      rebootWindow = mkForce { lower = "12:00"; upper = "21:00"; };
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
      (mkIf config.system.autoUpgrade.enable {
        services.nixos-upgrade.environment.GIT_SSH_COMMAND =
          concatStringsSep " " [
            "${pkgs.openssh}/bin/ssh"
            "-F /etc/ssh/ssh_config"
            "-i ${config.sops.secrets.nixos-config-deploy-key.path}"
            "-o IdentitiesOnly=yes"
            "-o StrictHostKeyChecking=yes"
          ];
      })
    ];

    hardware = {
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    };

    nixpkgs.config.allowUnfree = true;
  };
}

