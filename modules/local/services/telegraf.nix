{ config, lib, pkgs, secrets, ... }: with lib; let
  cfg = config.local.services.telegraf;

  # Telegraf custom_builder utility
  custom-builder = pkgs.buildPackages.buildGoModule {
    # Use same pname to reuse vendored modules
    pname = "telegraf";
    inherit (pkgs.telegraf) version src vendorHash proxyVendor;

    subPackages = [ "tools/custom_builder" ];
  };

  # Unused, but provides an example of how to generate go build tags for a
  # config
  tags = configFile: pkgs.stdenv.mkDerivation {
    name = "telegraf-custom-build-tags";
    inherit (pkgs.telegraf) src;

    nativeBuildInputs = [ pkgs.go custom-builder ];

    buildPhase = ''
      HOME=$(pwd)
      custom_builder --config ${configFile} --dry-run --tags | tee "$out"
    '';
  };
in {
  options.local.services.telegraf = {
    enable = mkEnableOption "Telegraf machine telemetry logging";

    buildTags = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = ''
        Tags to pass to package build to selectively build only the plugins
        required by a particular config in order to reduce binary size. The
        list of required tags may be generated using the custom_build tool
        included in the telegraf source.
        See: https://www.influxdata.com/blog/how-reduce-telegraf-binary-size/
      '';
    };

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
    local.services.telegraf.buildTags = [
      "outputs.influxdb"
    ] ++ lib.optionals cfg.enableSystemMetrics [
      "inputs.cpu"
      "inputs.disk"
      "inputs.diskio"
      "inputs.mem"
      "inputs.net"
      "inputs.netstat"
      "inputs.ping"
      "inputs.processes"
      "inputs.system"
    ];

    services.telegraf = {
      enable = true;

      package = pkgs.telegraf.overrideAttrs ({ tags ? [], ...}: {
        tags = tags ++ [ "custom" ] ++ cfg.buildTags;
        # Tests depend on plugins that may be disabled
        doCheck = false;
      });

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

            ## If true, no CREATE DATABASE queries will be sent. Set to true when using
            ## Telegraf with a user without permissions to create databases or when the
            ## database already exists.
            skip_database_creation = true;

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
