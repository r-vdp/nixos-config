{ inputs, lib, pkgs, config, ... }:
{
  options = {
    settings.fwupd.flashrom.enable =
      lib.mkEnableOption "our custom fwupd package with flashrom support";
  };

  config = lib.mkIf config.settings.fwupd.flashrom.enable {
    services = {
      fwupd = {
        enable = true;
        package = pkgs.fwupd.override {
          enableFlashrom = true;
          flashrom = config.programs.flashrom.package;
        };
      };
    };

    programs.flashrom = {
      enable = true;
      package = inputs.self.packages.${pkgs.system}.flashrom;
    };
  };
}
