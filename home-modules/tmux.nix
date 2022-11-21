{ osConfig, ... }:

{
  programs.tmux = {
    enable = true;
    newSession = true;
    clock24 = true;
    historyLimit = 10000;
    escapeTime = 250;
    terminal = osConfig.settings.system.tmux_term;
    keyMode = "vi";
    extraConfig = ''
      set -g mouse on
      set-option -g focus-events on
      set-option -sa terminal-overrides ',xterm-256color:RGB'
    '';
  };
}


