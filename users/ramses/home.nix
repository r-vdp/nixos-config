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
      pcloud
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
