{ config, ... }:

{
  programs.alacritty = {
    enable = ! config.home.settings.isHeadless;
    settings = {
      font.size = 12;
      draw_bold_text_with_bright_colors = true;

      # See https://github.com/leifmetcalf/alacritty-gnome-theme/
      colors = {
        primary = {
          foreground = "#d0cfcc";
          background = "#171421";
          bright_foreground = "#ffffff";
        };
        normal = {
          black = "#171421";
          red = "#c01c28";
          green = "#26a269";
          yellow = "#a2734c";
          blue = "#12488b";
          magenta = "#a347ba";
          cyan = "#2aa1b3";
          white = "#d0cfcc";
        };
        bright = {
          black = "#5e5c64";
          red = "#f66151";
          green = "#33d17a";
          yellow = "#e9ad0c";
          blue = "#2a7bde";
          magenta = "#c061cb";
          cyan = "#33c7de";
          white = "#ffffff";
        };
      };
    };
  };
}

