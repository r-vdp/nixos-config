{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      fwupd = final.callPackage ../../overrides/fwupd { };

      flashrom = prev.flashrom.overrideAttrs (prevAttrs: rec {
        version = "1.3.0-rc2";

        src = final.fetchFromGitHub {
          owner = prevAttrs.pname;
          repo = prevAttrs.pname;
          rev = "v${version}";
          hash = "sha256-s69mJfTk1Y1TUV5etXc0A1vcHYH6cn2Nx56KirU1j+s=";
        };

        nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with final.pkgs; [
          meson
          ninja
        ]);

        buildInputs = prevAttrs.buildInputs ++ (with final.pkgs; [
          #  libjaylink
          cmocka
        ]);

        mesonFlags = [
          "-Dprogrammer=auto"
        ];

        postInstall = ''
          install -Dm644 $src/util/flashrom_udev.rules $out/lib/udev/rules.d/flashrom.rules
          substituteInPlace $out/lib/udev/rules.d/flashrom.rules \
            --replace "plugdev" "flashrom"
        '';

        postPatch = "";
      });
    })
  ];

  # Issue with fwupd since it cannot write in the fwupd directory in /etc
  # https://github.com/NixOS/nixpkgs/pull/212440
  environment.etc."fwupd/uefi_capsule.conf" = lib.mkForce { text = ""; };

  services.fwupd.daemonSettings = {
    EspLocation = config.boot.loader.efi.efiSysMountPoint;
  };

  environment.systemPackages = with pkgs; [
    coreboot-configurator
  ];

  programs.flashrom.enable = true;

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
