{ config, ... }:
{
  home = {
    settings = {
      isHeadless = true;
      neovim.enableFullDevelopEnv = false;
    };
    stateVersion = "22.11";
  };
}
