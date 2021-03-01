{ config, lib, pkgs, secrets, ... }: with lib; {
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ../../machines + "/${config.networking.hostName}/telegraf/client.pem";
      tlsKeySecret = secrets."${config.networking.hostName}".telegraf.sslClientCertificateKey;
    };
  };
}
