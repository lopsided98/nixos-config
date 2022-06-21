{ config, lib, pkgs, secrets, inputs, ... }:

with lib;

let
  cfg = config.local.services.waterLevelMonitor;
in {
  imports = [ inputs.water-level-monitor.nixosModule ];

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

    systemd = {
      #notifyFailed.enable = true;
      #services.water-level-base-station.notifyFailed = true;

      secrets.water-level-base-station = {
        units = [ "water-level-base-station.service" ];
        files = secrets.mkSecret cfg.certificateSecret { user = "water-level"; };
      };
    };
  };
}
