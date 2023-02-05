{ lib, pkgs, ... }:
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

      custom.mullvad = {
        when = ''${pkgs.mullvad}/bin/mullvad status | ${pkgs.ripgrep}/bin/rg "Connected"'';
        command = "echo '󰦝'";
        style = "bold green";
      };

      # Show a refresh symbol when the kernel changed and we need to reboot.
      custom.needs-reboot = {
        when =
          let
            curr-sys = "/run/current-system/";
            boot-sys = "/run/booted-system/";
            comparePaths = { filename, compareContents ? false }:
              let
                pathToValue = path:
                  if compareContents
                  then
                    "sha256sum ${path} | cut -d' ' -f1"
                  else
                    "realpath ${path}";

                currentValue = pathToValue "${curr-sys}/${filename}";
                bootedValue = pathToValue "${boot-sys}/${filename}";
              in
              ''test "$(${currentValue})" != "$(${bootedValue})"'';
          in
          lib.concatMapStringsSep " || " comparePaths [
            { filename = "kernel"; }
            { filename = "kernel-modules"; }
            # This file is part of the top-level system path, and so the realpath
            # changes every time we get a new system path.
            # We thus need to look at the actual contents to know if it changed.
            { filename = "kernel-params"; compareContents = true; }
            { filename = "initrd"; }
          ];
        command = "echo ''";
        style = "bold red";
      };
    };
  };
}
