{ pkgs, ... }:

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

  home-manager.sharedModules = [
    {
      home.packages = [
        # https://github.com/NixOS/nixpkgs/pull/217842
        #inputs.self.packages.${pkgs.system}.coreboot-configurator
        pkgs.via
      ];
    }
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
        device = "/dev/disk/by-partuuid/b4875b74-21ae-4789-8f21-03c6e5074914";
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
