{ lib, services, ... }:

with lib;

{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    # Don't allow users to manage their own authorized keys
    authorizedKeysFiles = mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
