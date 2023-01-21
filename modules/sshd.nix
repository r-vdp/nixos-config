{ lib, ... }:

with lib;

{
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    openFirewall = true;

    # Ignore the authorized_keys files in the users' home directories,
    # keys should be added through the config.
    authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      kbdInteractiveAuthentication = false;
      passwordAuthentication = false;
      permitRootLogin = "no";
    };
    forwardX11 = false;
    allowSFTP = true;
    kexAlgorithms = [
      "sntrup761x25519-sha512@openssh.com"
      "curve25519-sha256@libssh.org"
    ];
    ciphers = [
      "aes256-gcm@openssh.com"
      "chacha20-poly1305@openssh.com"
    ];
    macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
      "umac-128-etm@openssh.com"
    ];
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
