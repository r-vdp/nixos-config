{ config, lib, pkgs, ... }:

let
  cfg = config.settings.system;
in

{
  options.settings.system = {
    isHeadless = lib.mkOption {
      type = lib.types.bool;
    };

    isISO = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    isVM = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    nameservers = lib.mkOption {
      type = with lib.types; listOf str;
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

    tmux_term = lib.mkOption {
      type = lib.types.str;
      default = "tmux-256color";
      readOnly = true;
    };
  };

  config = {
    # Populate the man-db cache so that apropos works.
    # Also needed for manpage searching using telescope in neovim.
    documentation = {
      man = {
        enable = ! (cfg.isISO || cfg.isVM);
        generateCaches = true;
      };
      dev.enable = ! (cfg.isISO || cfg.isVM);
      info.enable = false;
      doc.enable = false;
    };

    # We don't want a nix channel for root.
    system.activationScripts.no-nix-channel = lib.stringAfter [ "nix" ] ''
      echo "" > /root/.nix-channels
    '';

    programs = {
      # We use nix-index instead, setup with home-manager
      command-not-found.enable = false;

      ssh = {
        knownHosts.github = {
          hostNames = [ "github.com" "ssh.github.com" ];
          publicKey =
            "ssh-ed25519 " +
            "AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };
        extraConfig = ''
          # Some internet providers block port 22,
          # so we connect to GitHub using port 443
          Host github.com
            HostName ssh.github.com
            User git
            Port 443
            UserKnownHostsFile /dev/null
        '';
      };
    };

    boot = {
      loader = lib.mkIf (! (cfg.isISO || cfg.isVM)) {
        systemd-boot = {
          enable = true;
          editor = false;
          configurationLimit = 100;
        };
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

    networking = {
      useNetworkd = true;
      firewall.allowedUDPPorts = [
        5353 # mDNS
      ];
      networkmanager = lib.mkIf config.networking.networkmanager.enable {
        # Do not take DNS servers from DHCP
        dns = lib.mkForce "none";
        wifi = {
          macAddress = "preserve";
        };
        # See https://developer-old.gnome.org/NetworkManager/stable/NetworkManager.html
        dispatcherScripts = [
          {
            # NetworkManager insist on setting per-interface DNS settings.
            # Since we always want to use the global settings, we reset these.
            # TODO: something seems to still reset these DNS settings without
            # retriggering this script...
            # TODO: is this still needed? Does resolved correctly use the global
            # settings only now due to them having Domains=~. ?
            source = pkgs.writeText "networkmanager-dispatcher-reset-dns" ''
              interface="$1"
              action="$2"

              echo "networkmanager-dispatcher-reset-dns: action=$action"
              if [ "$action" = "up" ] || \
                 [ "$action" = "dhcp4-change" ] || \
                 [ "$action" = "dhcp6-change" ] || \
                 [ "$action" = "connectivity-change" ]; then
                echo "networkmanager-dispatcher-reset-dns: configuring resolved for interface $1"
                ${lib.getBin pkgs.systemd}/resolvectl revert "$interface"
                ${lib.getBin pkgs.systemd}/resolvectl mdns "$interface" on
              fi
            '';
            type = "basic";
          }
        ];
      };
    };

    security = {
      sudo = {
        enable = true;
        execWheelOnly = true;
        wheelNeedsPassword = true;
      };
    };

    sops = {
      defaultSopsFile =
        lib.path.append ../secrets "${config.networking.hostName}-secrets.yaml";
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

    environment = {
      systemPackages = with pkgs; [
        ntfs3g
      ];

      shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];

      gnome.excludePackages =
        (with pkgs; [
          gnome-text-editor
          gnome-tour
          gnome-user-docs
        ]) ++ (with pkgs.gnome; [
          evince
          geary
          gnome-contacts
          gnome-maps
          gnome-music
          totem
        ]);
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 40;
    };

    services = {
      fwupd.enable = true;
      fstrim.enable = true;
      gvfs.enable = ! cfg.isHeadless;
      thermald.enable = true;

      # for dconf in home-manager
      dbus.packages = with pkgs; lib.optionals (! cfg.isHeadless) [
        dconf
      ];

      # https://flokli.de/posts/2022-11-18-nsncd/
      nscd.enableNsncd = true;

      timesyncd = {
        enable = ! cfg.isVM;
        servers = lib.mkDefault [
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
        # Make the global config the preferred one for all domains.
        domains = [ "~." ];
        dnssec = "false";
        extraConfig = ''
          DNS=${lib.concatStringsSep " " cfg.nameservers}
          DNSOverTLS=true
          MulticastDNS=true
        '';
      };

      avahi = {
        enable = false;
        nssmdns = true;
        publish = {
          enable = true;
          addresses = true;
        };
        openFirewall = true;
      };

      xserver = {
        enable = ! cfg.isHeadless;
        # Enable the GNOME Desktop Environment.
        displayManager.gdm.enable = ! cfg.isHeadless;
        desktopManager.gnome.enable = ! cfg.isHeadless;
        layout = "us";
        xkbVariant = "intl";
        excludePackages = with pkgs; [ xterm ];
      };

      # https://nixos.wiki/wiki/GNOME
      udev.packages = with pkgs; lib.optionals (! cfg.isHeadless) [
        gnome.gnome-settings-daemon
      ];

      # Enable CUPS to print documents.
      printing.enable = ! cfg.isHeadless;
    };

    fonts.fontconfig = {
      hinting = {
        enable = true;
        style = "hintfull";
      };
      subpixel.lcdfilter = "default";
    };

    # Enable sound with pipewire.
    sound.enable = false;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = ! cfg.isHeadless;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session desktopManager
      # (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    i18n = {
      defaultLocale = "en_GB.utf8";
      extraLocaleSettings = {
        LC_ADDRESS = "fr_BE.utf8";
        LC_IDENTIFICATION = "fr_BE.utf8";
        LC_MEASUREMENT = "fr_BE.utf8";
        LC_MONETARY = "fr_BE.utf8";
        LC_NAME = "fr_BE.utf8";
        LC_NUMERIC = "fr_BE.utf8";
        LC_PAPER = "fr_BE.utf8";
        LC_TELEPHONE = "fr_BE.utf8";
        LC_TIME = "fr_BE.utf8";
      };
    };

    # Configure console keymap
    console.keyMap = "us-acentos";

    system.autoUpgrade = {
      enable = cfg.isHeadless;
      flake = "git+ssh://github.com/R-VdP/nixos-config";
      flags = [
        "--refresh"
        "--no-update-lock-file"
        # We pull a remote repo into the nix store,
        # so we cannot write the lock file.
        "--no-write-lock-file"
      ];
      dates = "Fri 20:00";
      allowReboot = cfg.isHeadless;
      rebootWindow = { lower = "12:00"; upper = "21:00"; };
    };

    systemd = lib.mkMerge [
      (lib.mkIf cfg.isHeadless {
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
      (lib.mkIf config.system.autoUpgrade.enable {
        services.nixos-upgrade.environment.GIT_SSH_COMMAND =
          lib.concatStringsSep " " [
            "${lib.getBin pkgs.openssh}/ssh"
            "-F /etc/ssh/ssh_config"
            "-i ${config.sops.secrets.nixos-config-deploy-key.path}"
            "-o IdentitiesOnly=yes"
            "-o StrictHostKeyChecking=yes"
          ];
      })
      {
        # The notion of "online" is a broken concept
        # https://github.com/systemd/systemd/blob/e1b45a756f71deac8c1aa9a008bd0dab47f64777/NEWS#L13
        network.wait-online.enable = false;
        services.NetworkManager-wait-online.enable = false;
      }
      {
        # Use `systemctl restart` rather than stopping with `systemctl stop`
        # followed by a delayed `systemctl start`.
        services = {
          # Do not take down the network for too long when upgrading,
          # This also prevents failures of services that are restarted instead of stopped.
          systemd-networkd.stopIfChanged = false;
          # Services that are only restarted might not be able to resolve when resolved is stopped
          systemd-resolved.stopIfChanged = false;
        };
      }
    ];

    hardware = {
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    };

    # Adapt some settings in case we are building the config as a QEMU VM
    virtualisation.vmVariant = { lib, ... }: {
      settings.system = {
        isVM = true;
        isHeadless = lib.mkForce true;
      };
      # Needed to get the keyboard to work
      boot.kernelParams = [ "console=ttyS0" ];
      virtualisation = {
        cores = 2;
        memorySize = 4 * 1024;
        diskSize = 20 * 1024;
        writableStoreUseTmpfs = false;
        # Set to true to get a GUI
        graphics = false;
        qemu = {
          options = [
            "-machine accel=kvm"
          ];
          guestAgent.enable = true;
        };
      };
      # The VM cannot decrypt our secrets...
      users.users.ramses = {
        password = lib.mkForce "";
        passwordFile = lib.mkForce null;
      };
      services.getty.autologinUser = "ramses";
      security.sudo.wheelNeedsPassword = lib.mkForce false;
      users.mutableUsers = lib.mkForce false;
      # Avoid delays on boot of the VM
      networking.interfaces = lib.mkForce { };
      documentation = {
        nixos.enable = false;
      };
    };
  };
}
