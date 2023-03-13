{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  settings = {
    system.isHeadless = false;
    fileSystems.btrfs.enable = true;
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
