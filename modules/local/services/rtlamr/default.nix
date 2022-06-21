{ config, lib, pkgs, secrets, inputs, ... }:

with lib;

let
  cfg = config.local.services.rtlamr;
in {
  imports = [ inputs.nix-sdr.nixosModule ];

  options.local.services.rtlamr = {
    enable = mkEnableOption "power usage logging with RTL-SDR and InfluxDB";
  };

  config = mkIf cfg.enable {
    services.rtl-tcp.enable = true;

    services.rtlamr-collect = {
      enable = true;
      filterId = "44904168";
      influxdb = {
        hostName = "https://influxdb.benwolsieffer.com:8086";
        # Authentication is done with client certificate
        token = "rtlamr:invalid";
        bucket = "rtlamr";
        clientCert = ./influxdb.crt;
        clientKey = secrets.getSystemdSecret "rtlamr" secrets.rtlamr.influxdbClientKey;
      };
    };

    systemd.services.rtlamr-collect = {
      wants = [ "rtl-tcp.service" ];
      after = [ "rtl-tcp.service" ];
      notifyFailed = true;
    };

    systemd.secrets.rtlamr = {
      files = secrets.mkSecret secrets.rtlamr.influxdbClientKey {
        user = "rtlamr-collect";
      };
      units = singleton "rtlamr-collect.service";
    };

    systemd.notifyFailed.enable = true;
  };
}
