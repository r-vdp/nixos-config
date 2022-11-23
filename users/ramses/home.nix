{ osConfig, config, lib, pkgs, ... }:

with lib;

let
  isHeadless = osConfig.settings.system.isHeadless;
in
{
  home = {
    settings = {
      keys = {
        privateKeyFile =
          osConfig.sops.secrets."${config.home.username}-ssh-priv-key".path;
        publicKey =
          "ssh-ed25519 " +
          "AAAAC3NzaC1lZDI1NTE5AAAAIFDyV+zVbtGMdiRwSBnnkcHtZAe2F/zmBUDUqMY4Sr+K";
      };

      git = {
        userName = "R-VdP";
        userEmail = "141248+R-VdP@users.noreply.github.com";
      };
    };

    packages = with pkgs;
      optionals (! isHeadless) [
        authy
        gimp
        keepassxc
        nerdfonts
        pavucontrol
        pcloud
        signal-desktop
        slack
        teams
        vlc
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

