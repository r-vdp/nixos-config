{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    coreboot-configurator
  ];

  services.fwupd = {
    enable = true;
    package = pkgs.fwupd.override {
      enableFlashrom = true;
      flashrom = config.programs.flashrom.package;
    };
  };

  programs.flashrom = {
    enable = true;
    package =
      let
        version = "1.3.0-rc2";
        hash = "sha256-s69mJfTk1Y1TUV5etXc0A1vcHYH6cn2Nx56KirU1j+s=";
      in
      pkgs.flashrom.overrideAttrs (prevAttrs: {
        inherit version;

        src = pkgs.fetchFromGitHub {
          owner = prevAttrs.pname;
          repo = prevAttrs.pname;
          rev = "v${version}";
          inherit hash;
        };

        nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with pkgs; [
          meson
          ninja
        ]);

        buildInputs = prevAttrs.buildInputs ++ (with pkgs; [
          cmocka
        ]);

        postPatch = ''
          substituteInPlace util/flashrom_udev.rules --replace "plugdev" "flashrom"
        '';

        mesonFlags = [
          "-Dprogrammer=auto"
        ];

        postInstall = ''
          install -Dm644 $src/util/flashrom_udev.rules $out/lib/udev/rules.d/flashrom.rules
        '';
      });
  };

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
