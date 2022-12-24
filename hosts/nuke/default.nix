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
        device = "/dev/disk/by-partuuid/4cd65b64-7917-4e11-8b8c-e178ef8c53bf";
        allowDiscards = true;
        preLVM = true;
      };
    };
  };

  fileSystems = {
    "/" =
      {
        device = "/dev/volgroup/nixos";
        fsType = "btrfs";
        options = [ "defaults" "noatime" "acl" "compress=zstd" "subvol=root" ];
      };
    "/home" =
      {
        device = "/dev/volgroup/nixos";
        fsType = "btrfs";
        options = [ "defaults" "relatime" "acl" "compress=zstd" "subvol=home" ];
      };
    "/nix" =
      {
        device = "/dev/volgroup/nixos";
        fsType = "btrfs";
        options = [ "defaults" "noatime" "compress=zstd" "subvol=nix" ];
      };
    "/snapshots" =
      {
        device = "/dev/volgroup/nixos";
        fsType = "btrfs";
        options = [ "defaults" "noatime" "compress=zstd" "subvol=snapshots" ];
      };
    "/boot" =
      {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  networking = {
    hostName = "nuke";
    networkmanager = {
      enable = true;
      # Do not take DNS servers from DHCP
      dns = mkForce "none";
      wifi = {
        macAddress = "preserve";
      };
    };
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
