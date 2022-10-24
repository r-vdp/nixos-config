{ config, lib, pkgs, nixos-channel, nixpkgs, ... }:

with lib;

let
  cfg = config.settings.system;
in

{
  options = {
    settings.system.withExtraPythonPackages = mkOption {
      type = with types; listOf (functionTo (listOf types.package));
      default = const [ ];
    };
  };

  config =
    {

      environment.sessionVariables = {
        XDG_CACHE_HOME = "\${HOME}/.cache";
        XDG_CONFIG_HOME = "\${HOME}/.config";
        XDG_DATA_HOME = "\${HOME}/.local/share";
        XDG_STATE_HOME = "\${HOME}/.local/state";
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
          git
          (pkgs.python3.withPackages (pyPkgs:
            concatMap (withPyPkgs: withPyPkgs pyPkgs) cfg.withExtraPythonPackages)
          )
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

      services =
        {
          fwupd.enable = true;

          resolved =
            let
              quad9 = "dns.quad9.net";
              nameservers = [
                "2620:fe::fe#${quad9}"
                "2620:fe::9#${quad9}"
                "9.9.9.9#${quad9}"
                "149.112.112.112#${quad9}"
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

      hardware.enableRedistributableFirmware = true;
    };
}

