{ config, lib, pkgs, ... }:

with lib;

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
          (readFile ./authorized_keys)
          # Old id_ec key
          (concatStringsSep " " [
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
    optionals (! isHeadless) [
      authy
      gimp
      gparted
      keepassxc
      libreoffice-fresh
      nerdfonts
      pavucontrol
      pcloud
      signal-desktop
      slack
      vlc

      gnome-extension-manager
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
