{
  programs.starship = {
    enable = true;
    settings = {
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
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
