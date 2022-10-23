{ config, pkgs, ... }:

{
  home = {
    username = "ramses";
    homeDirectory = "/home/" + config.home.username;
    stateVersion = "22.05";

    packages = with pkgs; [
      keepassxc
      signal-desktop
      slack
      dropbox
      pcloud
      authy
      vlc
    ];
  };

  programs = {
    home-manager.enable = true;

    firefox = {
      enable = true;
      package = pkgs.firefox-wayland;
      profiles.ramses = {
        isDefault = true;
        settings = {
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.startup.page" = 3;
          "browser.search.region" = "BE";
          "browser.tabs.warnOnClose" = true;
          "dom.security.https_only_mode" = true;
          "network.proxy.type" = 0;
          "network.trr.custom_uri" = "https://quad9.net/dns-query";
          "network.trr.default_provider_uri" = "https://quad9.net/dns-query";
          "network.trr.mode" = 2;
          "privacy.donottrackheader.enabled" = true;
          "spellchecker.dictionary" = "en-GB";
          # https://wiki.archlinux.org/title/Firefox#Hardware_video_acceleration
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
        };
        search = {
          default = "DuckDuckGo";
          force = true;
          engines =
            let
              nixos-icon =
                "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            in
            {
              "NixOS Packages" = {
                urls = [{
                  template = "https://search.nixos.org/packages";
                  params = [
                    { name = "type"; value = "packages"; }
                    { name = "channel"; value = "unstable"; }
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = nixos-icon;
                definedAliases = [ "@nixos-packages" "@np" ];
              };
              "NixOS Options" = {
                urls = [{
                  template = "https://search.nixos.org/options";
                  params = [
                    { name = "type"; value = "options"; }
                    { name = "channel"; value = "unstable"; }
                    { name = "query"; value = "{searchTerms}"; }
                  ];
                }];
                icon = nixos-icon;
                definedAliases = [ "@nixos-options" "@no" ];
              };
            };
        };
      };
    };

    git =
      let
        userEmail = "141248+R-VdP@users.noreply.github.com";
        signingKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDyV+zVbtGMdiRwSBnnkcHtZAe2F/zmBUDUqMY4Sr+K";
      in
      {
        enable = true;
        userName = "R-VdP";
        inherit userEmail;
        extraConfig = {
          core = { };
          gpg = {
            format = "ssh";
            ssh.allowedSignersFile =
              let
                signers = ''
                  ${userEmail} ${signingKey}
                '';
              in
              ''${pkgs.writeText "git-allowed-signers" signers}'';
          };
          user = { inherit signingKey; };
          commit.gpgsign = true;
          tag.gpgsign = true;
        };
      };
  };
}

