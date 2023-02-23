{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  environment.systemPackages =
    let
      # https://github.com/NixOS/nixpkgs/pull/217842
      coreboot-configurator =
        let
          pkgFun =
            { lib
            , stdenv
            , fetchFromGitHub
            , inkscape
            , meson
            , mkDerivation
            , ninja
            , pkg-config
            , yaml-cpp
            , nvramtool
            , systemd
            , qtbase
            , qtsvg
            , wrapQtAppsHook
            }:

            mkDerivation {
              pname = "coreboot-configurator";
              version = "unstable-2023-01-17";

              src = fetchFromGitHub {
                owner = "StarLabsLtd";
                repo = "coreboot-configurator";
                rev = "944b575dc873c78627c352f9c1a1493981431a58";
                sha256 = "sha256-ReWQNzeoyTF66hVnevf6Kkrnt0/PqRHd3oyyPYtx+0M=";
              };

              nativeBuildInputs = [ inkscape meson ninja pkg-config wrapQtAppsHook ];
              buildInputs = [ yaml-cpp qtbase qtsvg ];

              postPatch = ''
                substituteInPlace src/application/*.cpp \
                  --replace '/usr/bin/pkexec' '/run/wrappers/bin/pkexec' \
                  --replace '/usr/bin/systemctl' '${systemd}/bin/systemctl' \
                  --replace '/usr/sbin/nvramtool' '${nvramtool}/bin/nvramtool'

                substituteInPlace src/resources/org.coreboot.nvramtool.policy \
                  --replace '/usr/sbin/nvramtool' '${nvramtool}/bin/nvramtool'

                substituteInPlace src/resources/org.coreboot.reboot.policy \
                  --replace '/usr/sbin/reboot' '${systemd}/bin/systemctl reboot'
              '';

              postFixup = ''
                substituteInPlace $out/share/applications/coreboot-configurator.desktop \
                  --replace '/usr/bin/coreboot-configurator' 'coreboot-configurator'
              '';

              meta = with lib; {
                description = "A simple GUI to change settings in Coreboot's CBFS";
                homepage = "https://support.starlabs.systems/kb/guides/coreboot-configurator";
                license = licenses.gpl2Only;
                platforms = platforms.linux;
                maintainers = with maintainers; [ danth ];
              };
            };
        in
        pkgs.libsForQt5.callPackage pkgFun { };
    in
    with pkgs; [
      coreboot-configurator
      via
    ];

  services = {
    udev.packages = with pkgs; [
      via
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
        hash = "sha256-rXwD8kpIrmmGJQu0NHHjIPGTa4+xx+H0FdqwAwo6ePg=";
      in
      pkgs.flashrom.overrideAttrs (prevAttrs: {
        src = pkgs.fetchzip {
          url = "https://download.flashrom.org/releases/flashrom-v${prevAttrs.version}.tar.bz2";
          inherit hash;
        };

        nativeBuildInputs = prevAttrs.nativeBuildInputs ++ (with pkgs; [
          meson
          ninja
        ]);

        buildInputs = prevAttrs.buildInputs ++ (with pkgs; [
          cmocka
        ]);

        mesonFlags = [
          "-Dprogrammer=auto"
        ];

        postInstall =
          let
            udevRulesPath = "lib/udev/rules.d/flashrom.rules";
          in
          ''
            # After the meson build, the udev rules file is no longer present
            # in the build dir, so we need to get it from $src and patch it
            # again.
            # There might be a better way to do this...
            install -Dm644 $src/util/flashrom_udev.rules $out/${udevRulesPath}
            substituteInPlace $out/${udevRulesPath} --replace 'GROUP="plugdev"' 'TAG+="uaccess", TAG+="udev-acl"'
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
