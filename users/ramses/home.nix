{ config, lib, pkgs, ... }:

let
  inherit (config.home.settings) isHeadless;
in
{
  imports = [ ./dconf.nix ];

  home = {
    settings = {
      git = {
        userName = "R-VdP";
        userEmail = "141248+R-VdP@users.noreply.github.com";
        signerKeys = [
          (lib.readFile ./authorized_keys)
          # Old id_ec key
          (lib.concatStringsSep " " [
            ''valid-before="20221201"''
            "ssh-ed25519"
            "AAAAC3NzaC1lZDI1NTE5AAAAIFDyV+zVbtGMdiRwSBnnkcHtZAe2F/zmBUDUqMY4Sr+K"
          ])
        ];
      };
    };

    packages = with pkgs; [
      jq
    ] ++
    lib.optionals (! isHeadless) [
      authy
      gimp
      gparted
      keepassxc
      libreoffice-fresh
      nerdfonts
      pavucontrol
      #pcloud
      # https://github.com/NixOS/nixpkgs/pull/216298
      (pcloud.overrideAttrs
        (oldAttrs:
          let
            code = "XZwHPTVZ7J1WFU374k8BqSWO2519y4aGFdAV";
            version = "1.10.1";

            # Archive link's codes: https://www.pcloud.com/release-notes/linux.html
            src = fetchzip {
              url = "https://api.pcloud.com/getpubzip?code=${code}&filename=${oldAttrs.pname}-${version}.zip";
              hash = "sha256-Mum1SL/EZ7iFK9e3o+T0CxkAQ0FkjSBy2FEUDonxtTI=";
            };

            appimageContents = appimageTools.extractType2 {
              name = "${oldAttrs.pname}-${version}";
              src = "${src}/pcloud";
            };
          in
          {
            inherit version;

            src = appimageContents;
          }))
      signal-desktop
      slack
      vlc

      gnome.gnome-tweaks
      gnomeExtensions.bluetooth-quick-connect
      gnomeExtensions.appindicator
      gnomeExtensions.system-monitor
    ];

    pointerCursor = {
      name = "Vanilla-DMZ";
      package = pkgs.vanilla-dmz;
      size = 24;
    };
  };
}
