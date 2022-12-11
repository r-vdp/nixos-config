{ config, lib, pkgs, ... }:

with lib;

let
  isHeadless = config.home.settings.isHeadless;
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

    shellAliases = {
      # Use --all twice to also show . and ..
      ls = "${pkgs.exa}/bin/exa";
      ll = "${pkgs.exa}/bin/exa --long --group --git --icons";
      la = "${pkgs.exa}/bin/exa --long --group --all --all --git --icons";
      lt = "${pkgs.exa}/bin/exa --tree --long --group --git --icons";

      nix-env = ''printf "The nix-env command has been disabled." 2> /dev/null'';
      # Have bash resolve aliases with sudo
      # https://askubuntu.com/questions/22037/aliases-not-available-when-using-sudo
      sudo = "sudo ";
      whereami = "curl ipinfo.io";
    };
  };

  programs = {
    bash.enable = true;
    zsh = {
      enable = true;
      enableSyntaxHighlighting = true;
      enableVteIntegration = true;
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
      };
    };

    exa.enable = true;
    starship.enable = true;

    alacritty = {
      enable = true;
      settings = {
        font.size = 9;
      };
    };
  };
}

