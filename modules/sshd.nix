{ lib, config, ... }:

{
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
    openFirewall = true;

    # Ignore the authorized_keys files in the users' home directories,
    # keys should be added through the config.
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      inherit (config.settings.shared.ssh) Ciphers Macs KexAlgorithms;

      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      GSSAPIAuthentication = false;
      KerberosAuthentication = false;
      PermitRootLogin = "no";

      X11forwarding = false;
      StrictModes = true;
      AllowAgentForwarding = false;
      TCPKeepAlive = true;

      ClientAliveInterval = 10;
      ClientAliveCountMax = 5;
    };
    allowSFTP = true;
  };
}
