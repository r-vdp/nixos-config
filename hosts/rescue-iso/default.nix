{ inputs, config, pkgs, lib, modulesPath, ... }:

with lib;

{
  imports = [
    "${modulesPath}/installer/cd-dvd/iso-image.nix"
  ];

  networking = {
    hostName = "rescue-iso";
    wireless.enable = mkOverride 10 false;
  };

  nixpkgs.hostPlatform = inputs.flake-utils.lib.system.x86_64-linux;

  system = {
    extraDependencies = mkOverride 10 [ ];
    stateVersion = "22.05"; # Did you read the comment?
  };

  security.sudo.wheelNeedsPassword = mkForce false;

  settings.system = {
    isHeadless = true;
    isISO = true;
  };

  fileSystems = mkForce config.lib.isoFileSystems;

  systemd.services.sshd.wantedBy = mkOverride 10 [ "multi-user.target" ];

  services.getty.helpLine = mkForce "";

  documentation = {
    enable = mkOverride 10 false;
    nixos.enable = mkOverride 10 false;
  };

  boot.supportedFilesystems = mkOverride 10 [
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
      makeEfiBootable = true;
      makeUsbBootable = true;

      # Faster build by compressing less
      squashfsCompression = "gzip -Xcompression-level 1";

      isoName = mkForce (
        (concatStringsSep "-" [
          custom_name
          config.isoImage.isoBaseName
          config.system.nixos.label
          pkgs.stdenv.hostPlatform.system
        ]) + ".iso"
      );
      appendToMenuLabel = " ${custom_name}";
    };
}
