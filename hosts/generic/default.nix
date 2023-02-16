{ config, ... }:
{
  home = {
    settings = {
      isHeadless = true;
      neovim.enableFullDevelopmentEnv = false;
    };
    stateVersion = "22.11";
  };
}
