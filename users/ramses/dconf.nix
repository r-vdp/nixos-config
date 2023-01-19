{ lib, config, ... }:

with lib;

{
  dconf.settings = with lib.hm.gvariant;
    let
      mkLocationEntry = name: code: { dblVal0, dblVal1, dblVal2, dblVal3 }:
        (mkVariant (mkTuple [
          (mkUint32 2)
          (mkVariant (mkTuple [
            name
            code
            true
            [ (mkTuple [ dblVal0 dblVal1 ]) ]
            [ (mkTuple [ dblVal2 dblVal3 ]) ]
          ]))
        ]));
      locations = {
        cairo = mkLocationEntry "Cairo" "HECA" {
          dblVal0 = 0.52592587544986047;
          dblVal1 = 0.54803338512621935;
          dblVal2 = 0.52447144022429604;
          dblVal3 = 0.54541539124822791;
        };
        brussels = mkLocationEntry "Brussels" "EBBR" {
          dblVal0 = 0.88837258926511375;
          dblVal1 = 0.079121586939312094;
          dblVal2 = 0.88720903061268674;
          dblVal3 = 0.07563092843532343;
        };
        toronto = mkLocationEntry "Toronto" "CYTZ" {
          dblVal0 = 0.76154532446909495;
          dblVal1 = -1.3857914260834978;
          dblVal2 = 0.76212711252195475;
          dblVal3 = -1.3860823201099277;
        };
      };
    in
    mkIf (! config.home.settings.isHeadless) {
      "org/gnome/Console" = {
        font-scale = 1.3000000000000003;
      };
      "org/gnome/desktop/input-sources" = {
        sources =
          mkArray
            (type.tupleOf [ type.string type.string ])
            [ (mkTuple [ "xkb" "us+intl" ]) ];
        xkb-options = mkArray type.string [ "terminate:ctrl_alt_bksp" ];
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        enable-hot-corners = false;
        show-battery-percentage = true;
        clock-show-seconds = false;
        clock-show-weekday = true;
        font-antialiasing = "rgba";
        font-hinting = "full";
        text-scaling-factor = 1.0;
      };
      "org/gnome/desktop/peripherals/mouse" = {
        natural-scroll = true;
        speed = 0.6;
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        two-finger-scrolling-enabled = true;
      };
      "org/gnome/desktop/privacy" = {
        old-files-age = mkUint32 30;
        recent-files-max-age = 30;
        remove-old-temp-files = true;
        remove-old-trash-files = true;
      };
      "org/gnome/desktop/session" = {
        idle-delay = mkUint32 600;
      };
      "org/gnome/desktop/sound" = {
        event-sounds = false;
        theme-name = "__custom";
      };
      "org/gnome/desktop/wm/keybindings" = {
        switch-applications = mkEmptyArray type.string;
        switch-applications-backward = mkEmptyArray type.string;
        switch-windows = mkArray type.string [ "<Alt>Tab" ];
        switch-windows-backward = mkArray type.string [ "<Shift><Alt>Tab" ];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        mic-mute = mkArray type.string [ "<Control><Super>m" ];
        volume-down = mkArray type.string [ "<Control><Super>Down" ];
        volume-mute = mkArray type.string [ "<Control><Super>v" ];
        volume-up = mkArray type.string [ "<Control><Super>Up" ];
      };
      "org/gnome/nautilus/preferences" = {
        click-policy = "single";
        default-folder-viewer = "icon-view";
        migrated-gtk-settings = true;
        search-filter-time-type = "last_modified";
        show-delete-permanently = true;
      };
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
      };
      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "hibernate";
        power-saver-profile-on-low-battery = true;
        sleep-inactive-ac-timeout = 7200;
        sleep-inactive-ac-type = "nothing";
      };
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = mkArray type.string [
          "system-monitor@paradoxxx.zero.gmail.com"
          "appindicatorsupport@rgcjonas.gmail.com"
        ];
        favorite-apps = mkArray type.string [
          "Alacritty.desktop"
          "firefox.desktop"
          "signal-desktop.desktop"
          "slack.desktop"
          "authy.desktop"
          "org.gnome.Calendar.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };
      "org/gnome/shell/extensions/appindicator" = {
        tray-pos = "right";
      };
      "org/gnome/shell/extensions/system-monitor" = {
        compact-display = false;
        move-clock = false;

        cpu-show-text = false;
        cpu-individual-cores = false;
        cpu-refresh-time = 2000;

        freq-display = true;
        freq-freq-color = "#c061cbff";
        freq-refresh-time = 2000;
        freq-show-menu = true;
        freq-show-text = false;

        memory-display = true;
        memory-refresh-time = 5000;
        memory-show-text = false;

        disk-display = true;
        disk-refresh-time = 2000;
        disk-show-text = false;

        net-display = true;
        net-refresh-time = 2000;
        net-show-text = false;

        swap-display = false;
        thermal-display = false;
      };
      "org/gnome/shell/weather" = {
        automatic-location = true;
      };
      "org/gnome/shell/world-clocks" = {
        locations = mkArray type.variant (attrValues locations);
      };
    };
}
