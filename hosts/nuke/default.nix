{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  settings = {
    system.isHeadless = false;
    fwupd.flashrom.enable = true;
    intelGraphics.enable = true;
  };

  environment.systemPackages = with pkgs; [
    via
  ];

  services = {
    udev.packages = with pkgs; [
      via
    ];
  };

  time.timeZone = "Europe/Brussels";

  boot = {
    #extraModprobeConfig = ''
    #  options snd-hda-intel power_save=1
    #'';
    initrd.luks.devices = {
      decrypted = {
        device = "/dev/disk/by-partuuid/4cd65b64-7917-4e11-8b8c-e178ef8c53bf";
        allowDiscards = true;
        bypassWorkqueues = true;
        preLVM = true;
      };
    };
    kernelModules = [ "i915" ];
    # Force our display to its native 1440p resolution
    # The right connector type can be found with the following command:
    #   for p in /sys/class/drm/*/status; do con=${p%/status}; echo -n "${con#*/card?-}: "; cat $p; done
    kernelParams = [
      "video=HDMI-A-1:2560x1440"
    ];
  };

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
      "/snapshots" = {
        device = "/dev/volgroup/nixos";
        fsType = "btrfs";
        options = btrfsCommonOpts ++ [ "subvol=snapshots" ];
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

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  networking = {
    hostName = "nuke";
    networkmanager.enable = true;
  };

  # On CPUs using the intel_pstate scaling driver, there is no schedutil governor.
  # Only powersave and performance are available.
  # The powersave governor is in this case similar to schedutil.
  # https://www.kernel.org/doc/html/v4.12/admin-guide/pm/intel_pstate.html
  powerManagement.cpuFreqGovernor = "powersave";
}
