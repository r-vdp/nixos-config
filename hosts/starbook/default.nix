{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./hardware-configuration.nix
  ];

  time.timeZone = "Europe/Brussels";

  settings.system.isHeadless = false;

  boot = {
    initrd.luks.devices = {
      decrypted = {
        device = "/dev/disk/by-partuuid/aa63e87a-ca97-42be-8f15-1699e0978bb2";
        allowDiscards = true;
        preLVM = true;
      };
    };
  };

  fileSystems =
    let
      # We do not enable discard here, it is taken care of by an fstrim timer,
      # as recommended by the btrfs manpage.
      # ACL is enabled by default.
      btrfsCommonOpts = [ "defaults" "noatime" "compress=zstd" "autodefrag" ];
    in
    {
      "/" =
        {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=root" ];
        };
      "/home" =
        {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=home" ];
        };
      "/nix" =
        {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=nix" ];
        };
      "/snapshots" =
        {
          device = "/dev/volgroup/nixos";
          fsType = "btrfs";
          options = btrfsCommonOpts ++ [ "subvol=snapshots" ];
        };
      "/boot" =
        {
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
    hostName = "starbook";
    networkmanager.enable = true;
    extraHosts = ''
      # I hate captive portals
      41.128.153.50 ezxcess.antlabs.com
    '';
  };

  nixpkgs.config = {
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
    };
  };

  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
  };
}
