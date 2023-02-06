{ config, lib, pkgs, ... }:

let
  inherit (config.home) settings;
in

{
  options = {
    home.settings = {
      git = {
        userName = lib.mkOption {
          type = lib.types.str;
        };
        userEmail = lib.mkOption {
          type = lib.types.str;
        };
        signerKeys = lib.mkOption {
          type = with lib.types; listOf str;
        };
      };
    };
  };

  config.programs.git = {
    enable = true;
    inherit (settings.git) userName userEmail;
    ignores = [
      ".worktrees"
      "*.qcow2"
      "result"
    ];
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;

      # Signing
      gpg = {
        format = "ssh";
        ssh.allowedSignersFile =
          let
            mkLine = pubkey: ''${settings.git.userEmail} ${pubkey}'';
            signers = lib.concatMapStringsSep "\n" mkLine settings.git.signerKeys;
          in
          ''${pkgs.writeText "git-allowed-signers" signers}'';
      };
      user.signingKey = settings.keys.privateKeyFiles.current;
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
    difftastic = {
      enable = true;
      background = "dark";
    };
  };
}
