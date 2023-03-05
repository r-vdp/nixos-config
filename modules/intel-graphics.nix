{ lib, pkgs, config, ... }:
{
  options = {
    settings.intelGraphics.enable = lib.mkEnableOption "integrated Intel graphics";
  };

  config = lib.mkIf config.settings.intelGraphics.enable {
    nixpkgs.config = {
      packageOverrides = pkgs: {
        vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
      };
    };

    hardware.opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    environment.variables.VDPAU_DRIVER =
      lib.mkIf config.hardware.opengl.enable "va_gl";
  };
}
