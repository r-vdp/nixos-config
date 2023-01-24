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
        device = "/dev/disk/by-partuuid/07065c4d-825f-4a68-a388-8660c1dfed4a";
        header = "/dev/disk/by-partuuid/e1fda992-218c-4809-9522-01db59c8e6f8";
        allowDiscards = true;
        preLVM = true;
      };
    };
  };

  fileSystems = {
    "/" =
      {
        device = "/dev/disk/by-label/nixos-root";
        fsType = "ext4";
        options = [ "defaults" "noatime" "acl" ];
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
