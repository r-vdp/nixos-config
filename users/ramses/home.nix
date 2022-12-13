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
      # This option is relative to the home dir, so we cannot use the value of
      # config.xdg.configHome. We should file an issue for this.
      dotDir = ".config/zsh/";
      history.path = "${config.xdg.dataHome}/zsh/zsh_history";
      # The env vars somehow get overriden again by the values in /etc/(z)profile...
      # Not clear yet why or where.
      # We set them again here to avoid e.g. being dropped in nano.
      initExtra = ''
        unset __HM_SESS_VARS_SOURCED
        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
      '';
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
      };
    };

    exa.enable = true;
    starship.enable = true;
  };
}

