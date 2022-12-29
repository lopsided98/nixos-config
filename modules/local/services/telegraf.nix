{ config, lib, pkgs, secrets, ... }: with lib; let
  cfg = config.local.services.telegraf;
in {
  options.local.services.telegraf = {
    enable = mkEnableOption "Telegraf machine telemetry logging";

    enableSystemMetrics = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable collection of general system metrics such as CPU, memory and disk
        usage.
      '';
    };

    networkInterfaces = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = ''
        Network interfaces to measure. If null, collect data from all
        interfaces.
      '';
    };

    influxdb = {
      tlsCertificate = mkOption {
        type = types.path;
        description = "TLS client authentication certificate";
      };

      tlsKeySecret = mkOption {
        type = types.str;
        description = "TLS client authentication key secret";
      };
    };
  };

  config = mkIf cfg.enable {
    services.telegraf = {
      enable = true;
      extraConfig = {
        # Output plugins
        outputs = {
          influxdb = {
            ## The HTTP or UDP URL for your InfluxDB instance.  Each item should be
            ## of the form:
            ##   scheme "://" host [ ":" port]
            ##
            ## Multiple urls can be specified as part of the same cluster,
            ## this means that only ONE of the urls will be written to each interval.
            # urls = ["udp://localhost:8089"] # UDP endpoint example
            urls = [ "https://influxdb.benwolsieffer.com:8086" ];

            tls_cert = cfg.influxdb.tlsCertificate;
            tls_key = secrets.getSystemdSecret "telegraf" cfg.influxdb.tlsKeySecret;
          };
        };

        inputs = mkIf cfg.enableSystemMetrics {

          # Read metrics about cpu usage
          cpu = { };

          # Read metrics about disk usage by mount point
          disk = {
            interval = "5m";
            # Ignore bind mounts such as /nix/store
            ignore_mount_opts = [ "bind" ];
          };

          # Read metrics about disk IO by device
          diskio = {
            # By default, telegraf will gather stats for all devices including
            # disk partitions.
            # Setting devices will restrict the stats to the specified devices.
            devices = ["mmcblk1" "sda"];
          };

          # Read metrics about memory usage
          mem = {};

          # Get the number of processes and group them by status
          processes = {};

          # Read metrics about system load & uptime
          system = {};

          # Read metrics about network interface usage
          net = optionalAttrs (cfg.networkInterfaces != null) {
            # By default, telegraf gathers stats from any up interface (excluding loopback)
            # Setting interfaces will tell it to gather these explicit interfaces,
            # regardless of status.
            interfaces = cfg.networkInterfaces;
          };

          # Read TCP metrics such as established, time wait and sockets counts.
          netstat = {};
        };
      };
    };

    systemd.secrets.telegraf = {
      files = secrets.mkSecret cfg.influxdb.tlsKeySecret {
        user = "telegraf";
      };
      units = singleton "telegraf.service";
    };
  };
}
