{
  programs.starship = {
    enable = true;
    settings = {
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      directory = {
        fish_style_pwd_dir_length = 1;
        before_repo_root_style = "cyan";
        repo_root_style = "bold cyan underline";
        truncate_to_repo = false;
      };

      hostname = {
        # This symbol has some right padding, so we do not include an extra space.
        ssh_symbol = "🌐";
      };

      git_branch = {
        symbol = " ";
      };

      shell = {
        disabled = false;
        bash_indicator = "bash";
        fish_indicator = "";
      };

      memory_usage = {
        disabled = false;
        threshold = 60;
      };

      shlvl = {
        disabled = true;
        symbol = "";
      };

      # Show a refresh symbol when the kernel changed and we need to reboot.
      custom.kernel-version = {
        when =
          let
            curr-sys = "/run/current-system/";
            boot-sys = "/run/booted-system/";
            comparePaths = path:
              ''test "$(realpath ${curr-sys}/${path})" != "$(realpath ${boot-sys}/${path})"'';
          in
          ''${comparePaths "kernel"} && ${comparePaths "kernel-modules"}'';
        command = "echo ''";
        style = "bold red";
      };
    };
  };
}
