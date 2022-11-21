{ config, osConfig, pkgs, ... }:
{
  programs.firefox = {
    enable = ! osConfig.settings.system.isHeadless;
    package = pkgs.firefox-wayland;
    profiles.${config.home.username} = {
      isDefault = true;
      settings =
        let
          quad9 = "https://quad9.net/dns-query";
        in
        {
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.startup.page" = 3;
          "browser.search.region" = "BE";
          "browser.tabs.warnOnClose" = true;
          "dom.security.https_only_mode" = true;
          "network.proxy.type" = 0;
          "network.trr.custom_uri" = quad9;
          "network.trr.default_provider_uri" = quad9;
          "network.trr.uri" = quad9;
          "network.trr.mode" = 2;
          "network.trr.wait-for-portal" = true;
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
}

