{ lib, services, ... }:

with lib;

{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
    startWhenNeeded = true;
    # Don't allow users to manage their own authorized keys
    authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
  };
}
