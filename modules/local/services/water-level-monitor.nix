{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.waterLevelMonitor;
in {
  options.local.services.waterLevelMonitor = {
    enable = mkEnableOption "Water Level Monitor";

    influxdb = mkOption {
      type = types.submodule {
        options = {
          url = mkOption {
            type = types.str;
            default = "https://influxdb.benwolsieffer.com:8086";
            description = ''
              URL used to connect to InfluxDB.
            '';
          };

          database = mkOption {
            type = types.str;
            default = "maine";
            description = ''
              InfluxDB database name.
            '';
          };

          certificateSecret = mkOption {
            type = types.str;
            description = ''
              Secret containing the PKCS #12 certificate and private key used
              to authenticate with InfluxDB. This private key must have no
              password.
            '';
          };
        };
      };
      default = {};
    };

    address = mkOption {
      type = types.str;
      default = "C6:F8:64:2F:D9:D2";
      description = ''
        BLE address of the sensor.
      '';
    };
  };

  config = mkIf cfg.enable {
    users = {
      users.water-level = {
        isSystemUser = true;
        group = "water-level";
      };
      groups.water-level = {};
    };

    hardware.bluetooth.enable = true;

    services.dbus.packages = singleton (pkgs.writeTextFile {
      name = "dbus-water-level-bluetooth.conf";
      destination = "/etc/dbus-1/system.d/water-level-bluetooth.conf";
      text = ''
        <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
         "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
        <busconfig>
          <policy user="water-level">
            <allow send_destination="org.bluez"/>
          </policy>
        </busconfig>
      '';
    });

    systemd.services.water-level-base-station = let
      settings = pkgs.writeText "water-level-settings.yaml" (builtins.toJSON {
        influxdb = {
          inherit (cfg.influxdb) url database;
          certificate.file = secrets.getSecret cfg.influxdb.certificateSecret;
        };
        inherit (cfg) address;
      });
    in {
      environment.RUST_LOG = "debug";
      wantedBy = [ "multi-user.target" ];
      after = [ "bluetooth.target" ];
      serviceConfig = {
        User = "water-level";
        Group = "water-level";
        ExecStart = "${pkgs.water-level-base-station}/bin/water_level_base_station ${settings}";
      };
    };

    environment.secrets = secrets.mkSecret cfg.influxdb.certificateSecret {
      user = "water-level";
    };
  };
}
