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
    # https://github.com/NixOS/nixpkgs/pull/217842
    inputs.self.packages.${pkgs.system}.coreboot-configurator
    via
  ];

  services = {
    udev.packages = with pkgs; [
      via
    ];
  };

  time.timeZone = "Europe/Brussels";

  boot = {
    initrd.luks.devices = {
      decrypted = {
        device = "/dev/disk/by-partuuid/aa63e87a-ca97-42be-8f15-1699e0978bb2";
        allowDiscards = true;
        bypassWorkqueues = true;
        preLVM = true;
      };
    };
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
    hostName = "starbook";
    networkmanager.enable = true;
    extraHosts = ''
      # I hate captive portals
      41.128.153.50 ezxcess.antlabs.com
    '';
  };
}
