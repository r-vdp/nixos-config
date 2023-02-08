{ lib, ... }:

{
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    openFirewall = true;

    # Ignore the authorized_keys files in the users' home directories,
    # keys should be added through the config.
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      Ciphers = [
        "aes256-gcm@openssh.com"
        "chacha20-poly1305@openssh.com"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256@libssh.org"
      ];
      X11forwarding = false;
    };
    allowSFTP = true;
    extraConfig = ''
      StrictModes yes
      AllowAgentForwarding no
      TCPKeepAlive yes
      ClientAliveInterval 10
      ClientAliveCountMax 5
      GSSAPIAuthentication no
      KerberosAuthentication no
    '';
  };
}
