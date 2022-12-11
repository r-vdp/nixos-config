{ config, ... }:
{
  home = {
    settings = {
      isHeadless = true;
      # We have some customer-specific settings in our nix config on dev1
      nix.enable = false;
    };
    stateVersion = "22.05";
  };
}

