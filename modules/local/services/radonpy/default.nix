{ config, lib, pkgs, secrets, inputs, ... }:

with lib;

let
  cfg = config.local.services.radonpy;
in {
  imports = [ inputs.radonpy.nixosModule ];

  options.local.services.radonpy = {
    enable = mkEnableOption "radon level logging to InfluxDB from a RadonEye RD200";
  };

  config = mkIf cfg.enable {
    services.radonpy = {
      enable = true;
      address = "C8:AF:65:11:86:F8";
      influxdb = {
        excludeFields = [ "day_value" "month_value" ];
        url = "https://influxdb.benwolsieffer.com:8086";
        username = "radonpy";
        database = "radon";
        tlsCertificate = ./influxdb.crt;
        tlsKey = secrets.getSystemdSecret "radonpy" secrets.radonpy.influxdbClientKey;
      };
    };

    systemd = {
      notifyFailed.enable = true;
      services.radonpy.notifyFailed = true;

      secrets.radonpy = {
        files = secrets.mkSecret secrets.radonpy.influxdbClientKey {
          user = "radonpy";
        };
        units = singleton "radonpy.service";
      };
    };
  };
}
