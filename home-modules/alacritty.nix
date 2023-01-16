{ config, ... }:

{
  programs.alacritty = {
    enable = ! config.home.settings.isHeadless;
    settings = {
      window.decorations = "none";

      font =
        let
          # Tricky to find the right name, we can check the font picker of
          # any GUI program like Firefox and write exactly what is shown there.
          family = "FiraCode Nerd Font";
        in
        {
          normal = {
            inherit family;
            style = "Regular";
          };

          bold = {
            inherit family;
            style = "Bold";
          };

          italic = {
            inherit family;
            style = "Italic";
          };

          bold_italic = {
            inherit family;
            style = "Bold Italic";
          };

          size = 11;
        };

      draw_bold_text_with_bright_colors = true;

      # See https://github.com/leifmetcalf/alacritty-gnome-theme/
      colors = {
        primary = {
          foreground = "#d0cfcc";
          background = "#171417";
          bright_foreground = "#ffffff";
        };
        normal = {
          black = "#171417";
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
