{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    coreboot-configurator
    via
  ];

  services = {
    udev.packages = with pkgs; [
      qmk-udev-rules
    ];

    fwupd = {
      enable = true;
      package = pkgs.fwupd.override {
        enableFlashrom = true;
        flashrom = config.programs.flashrom.package;
      };
    };
  };

  programs.flashrom = {
    enable = true;
    package =
      let
        version = "1.3.0";
        hash = "sha256-rXwD8kpIrmmGJQu0NHHjIPGTa4+xx+H0FdqwAwo6ePg=";
      in
      pkgs.flashrom.overrideAttrs (prevAttrs: {
        inherit version;
        src = pkgs.fetchzip {
          url = "https://download.flashrom.org/releases/flashrom-v${version}.tar.bz2";
          inherit hash;
        };

        nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with pkgs; [
          meson
          ninja
        ]);

        buildInputs = prevAttrs.buildInputs ++ (with pkgs; [
          cmocka
        ]);

        # The original postPatch phase refers to the udev rules file that was
        # renamed in a later release.
        postPatch = "";

        mesonFlags = [
          "-Dprogrammer=auto"
        ];

        postInstall =
          let
            udevRulesPath = "lib/udev/rules.d/flashrom.rules";
          in
          ''
            install -Dm644 $src/util/flashrom_udev.rules $out/${udevRulesPath}
            substituteInPlace $out/${udevRulesPath} --replace "plugdev" "flashrom"
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
        bypassWorkqueues = true;
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
