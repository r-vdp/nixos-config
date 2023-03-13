{ lib, config, pkgs, ... }:

let
  cfg = config.settings.fileSystems.btrfs;
in
{
  options = {
    settings.fileSystems.btrfs = {
      enable = lib.mkEnableOption "our custom BTRFS module";
    };
  };

  config = lib.mkIf cfg.enable {
    fileSystems =
      let
        # We disable discard here, it is taken care of by an fstrim timer,
        # as recommended by the btrfs manpage.
        # ACL is enabled by default.
        btrfsCommonOpts = [ "defaults" "noatime" "compress=zstd" "autodefrag" "nodiscard" ];
      in
      {
        "/" = {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=root" ];
        };
        "/home" = {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=home" ];
        };
        "/nix" = {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=nix" ];
        };
        "/vol/snapshots" = {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=snapshots" ];
        };
        "/vol/volatile" = {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=volatile" ];
        };
        "/vol/persisted" = {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=persisted" ];
        };
        "/boot" = {
          device = "/dev/disk/by-label/ESP";
          fsType = "vfat";
          options = [ "defaults" "relatime" ];
        };
      };

    services.btrfs.autoScrub = {
      enable = true;
      # Only scrub one of the subvolumes, it will scrub the whole FS.
      fileSystems = [ "/" ];
    };

    systemd =
      let
        configs = {
          hourly = {
            volume = "home";
            frequency = "hourly";
            numberToKeep = "72";
          };
          daily = {
            volume = "home";
            frequency = "daily";
            numberToKeep = "20";
          };
          weekly = {
            volume = "home";
            frequency = "weekly";
            numberToKeep = "8";
          };
        };

        mkUnits = { volume, frequency, numberToKeep }:
          let
            unitName = "${volume}-${frequency}-snapshots";
          in
          {
            services."${unitName}" = {
              description = ''Make a snapshot of ${volume}'';
              serviceConfig = {
                Type = "oneshot";
              };
              script =
                let
                  destDir = "/vol/snapshots/${volume}/${frequency}";
                in
                ''
                  mkdir --parent "${destDir}"
                  ${lib.getBin pkgs.btrfs-progs}/bin/btrfs subvolume snapshot "/${volume}" "${destDir}/$(date --iso-8601=seconds)"

                  for path in $(${lib.getBin pkgs.fd}/bin/fd --max-depth=1 . "${destDir}" | sort | head -n -${numberToKeep}); do
                    echo "Removing subvolume: ''${path} ..."
                    ${lib.getBin pkgs.btrfs-progs}/bin/btrfs subvolume delete ''${path}
                  done
                '';
              restartIfChanged = false;
            };
            timers."${unitName}" = {
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = frequency;
                Persistent = true;
              };
            };
          };
      in
      lib.foldl (res: cfg: lib.recursiveUpdate res (mkUnits cfg)) { } (lib.attrValues configs);
  };
}
