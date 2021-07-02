{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.waterLevelMonitor;
in {
  options.local.services.waterLevelMonitor = {
    enable = mkEnableOption "Water Level Monitor";

    certificateSecret = mkOption {
      type = types.str;
      description = ''
        Secret containing the PKCS #12 certificate and private key used
        to authenticate with InfluxDB. This private key must have no
        password.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.waterLevelMonitor = {
      enable = true;
      influxdb.certificateFile = secrets.getSystemdSecret "water-level-base-station" cfg.certificateSecret;
    };

    systemd.secrets.water-level-base-station = {
      units = [ "water-level-base-station.service" ];
      files = secrets.mkSecret cfg.certificateSecret {};
    };
  };
}
