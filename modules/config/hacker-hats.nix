{ config, lib, pkgs, secrets, ... }: {
  services.hackerHats = {
    enable = true;
    virtualHost = "hackerhats.benwolsieffer.com";
    secretKeyFile = secrets.getSecret secrets.hackerHats.secretKey;
  };

  # Configure HTTPS
  services.nginx.virtualHosts."${config.services.hackerHats.virtualHost}" = {
    enableACME = true;
    forceSSL = true;
  };

  environment.secrets = secrets.mkSecret secrets.hackerHats.secretKey { user = "nginx"; };
}
