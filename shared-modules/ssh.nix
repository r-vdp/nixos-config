{ lib, ... }:

{
  options.settings.shared.ssh = {
    Ciphers = lib.mkOption {
      type = with lib.types; listOf str;
      readOnly = true;
      default = [
        "aes256-gcm@openssh.com"
        "chacha20-poly1305@openssh.com"
      ];
    };
    Macs = lib.mkOption {
      type = with lib.types; listOf str;
      readOnly = true;
      default =
        [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
    };
    KexAlgorithms = lib.mkOption {
      type = with lib.types; listOf str;
      readOnly = true;
      default =
        [
          "sntrup761x25519-sha512@openssh.com"
          "curve25519-sha256@libssh.org"
          "curve25519-sha256"
        ];
    };
  };
}
