{ osConfig, config, lib, pkgs, ... }:

with lib;

let
  isHeadless = osConfig.settings.system.isHeadless;
in
{

  imports = [ ./dconf.nix ];

  home = {
    settings = {
      keys = {
        privateKeyFiles = {
          id_ec = osConfig.sops.secrets."${config.home.username}-ssh-priv-key".path;
          current = osConfig.sops.secrets."${config.home.username}-2-ssh-priv-key".path;
        };
      };

      git = {
        userName = "R-VdP";
        userEmail = "141248+R-VdP@users.noreply.github.com";
        # TODO do we really want all of these?
        # Should we add valid-before on the old key?
        signerKeys =
          osConfig.users.users.${config.home.username}.openssh.authorizedKeys.keys;
      };
    };

    packages = with pkgs;
      optionals (! isHeadless) [
        authy
        gimp
        gparted
        keepassxc
        nerdfonts
        pavucontrol
        pcloud
        signal-desktop
        slack
        teams
        vlc

        gnome-extension-manager
        gnomeExtensions.appindicator
        gnomeExtensions.system-monitor
      ];
  };

  programs = {
    exa = {
      enable = true;
      enableAliases = true;
    };

    bash = {
      enable = true;
      shellAliases = {
        l = "${pkgs.exa}/bin/exa --long --group --git --icons";
        # Use --all twice to also show . and ..
        la = mkForce "${pkgs.exa}/bin/exa --long --group --all --all --git --icons";
        lt = mkForce "${pkgs.exa}/bin/exa --tree --long --group --git --icons";
        nix-env = ''printf "The nix-env command has been disabled." 2> /dev/null'';
        # Have bash resolve aliases with sudo
        # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
        sudo = "sudo ";
        whereami = "curl ipinfo.io";
      };
    };

    starship.enable = true;
  };
}

