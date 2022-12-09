{ inputs, config, pkgs, lib, modulesPath, ... }:

with lib;

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  nixpkgs.hostPlatform = inputs.flake-utils.lib.system.x86_64-linux;

  systemd.services.sshd.wantedBy = mkOverride 10 [ "multi-user.target" ];

  services.getty.helpLine = mkForce "";

  documentation = {
    enable = mkOverride 10 false;
    nixos.enable = mkOverride 10 false;
  };

  networking.wireless.enable = mkOverride 10 false;

  system.extraDependencies = mkOverride 10 [ ];

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

