{ config, lib, pkgs, ... }:

with lib;

let
  settings = config.home.settings;
in

{
  options = {
    home.settings = {
      git = {
        userName = mkOption {
          type = types.str;
        };
        userEmail = mkOption {
          type = types.str;
        };
        signerKeys = mkOption {
          type = with types; listOf str;
        };
      };
    };
  };

  config.programs.git = {
    enable = true;
    inherit (settings.git) userName userEmail;
    ignores = [
      ".worktrees"
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
            signers = concatMapStringsSep "\n" mkLine settings.git.signerKeys;
          in
          ''${pkgs.writeText "git-allowed-signers" signers}'';
      };
      user.signingKey = settings.keys.privateKeyFiles.current;
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };
}

