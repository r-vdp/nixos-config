{ inputs, config, pkgs, lib, modulesPath, ... }:

{
  networking = {
    hostName = "rescue-iso";
    wireless.enable = lib.mkOverride 10 false;
  };

  system = {
    extraDependencies = lib.mkOverride 10 [ ];
  };

  security.sudo.wheelNeedsPassword = lib.mkForce false;

  settings.system = {
    isHeadless = true;
    isISO = true;
  };

  fileSystems = lib.mkForce config.lib.isoFileSystems;

  users.users.ramses = {
    hashedPassword = lib.mkForce null;
    passwordFile = lib.mkForce null;
    # Empty password for auto login
    password = "";
  };

  systemd.services.sshd.wantedBy = lib.mkOverride 10 [ "multi-user.target" ];

  services.getty = {
    autologinUser = "ramses";
    helpLine = lib.mkForce "";
  };

  documentation = {
    enable = lib.mkOverride 10 false;
    nixos.enable = lib.mkOverride 10 false;
  };

  boot.supportedFilesystems = lib.mkOverride 10 [
    "vfat"
    "tmpfs"
    "auto"
    "squashfs"
    "tmpfs"
    "overlay"
  ];

  isoImage =
    let
      custom_name = "ramses-rescue-iso";
    in
    {
      # Faster build by compressing less
      squashfsCompression = "gzip -Xcompression-level 1";

      isoName = lib.mkForce (
        (lib.concatStringsSep "-" [
          custom_name
          config.isoImage.isoBaseName
          config.system.nixos.label
          pkgs.system
        ]) + ".iso"
      );
      appendToMenuLabel = " ${custom_name}";
    };
}
