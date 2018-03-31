{ config, lib, pkgs, secrets, ... }: with lib; {

  services.telegraf-fixed = {
    enable = true;

    agent = {
      # Default data collection interval for all inputs
      interval = "10s";

      # Telegraf will send metrics to outputs in batches of at most
      # metric_batch_size metrics.
      # This controls the size of writes that Telegraf sends to output plugins.
      metric_batch_size = 1000;

      # For failed writes, telegraf will cache metric_buffer_limit metrics for each
      # output, and will flush this buffer on a successful write. Oldest metrics
      # are dropped first when this buffer fills.
      # This buffer only fills when writes fail to output plugin(s).
      metric_buffer_limit = 10000;

      # Collection jitter is used to jitter the collection by a random amount.
      # Each plugin will sleep for a random time within jitter before collecting.
      # This can be used to avoid many plugins querying things like sysfs at the
      # same time, which can have a measurable effect on the system.
      collection_jitter = "0s";

      # Default flushing interval for all outputs. You shouldn't set this below
      # interval. Maximum flush_interval will be flush_interval + flush_jitter
      flush_interval = "10s";
      # Jitter the flush interval by a random amount. This is primarily to avoid
      # large write spikes for users running a large number of telegraf instances.
      # ie, a jitter of 5s and interval 10s means flushes will happen every 10-15s
      flush_jitter = "0s";

      # Logging configuration:
      # Run telegraf with debug log messages.
      debug = false;
      # Run telegraf in quiet mode (error log messages only).
      quiet = false;
      # Specify the log file name. The empty string means to log to stderr.
      logfile = "";

      # Override default hostname, if empty use os.Hostname()
      hostname = "";
      # If set to true, do no set the "host" tag in the telegraf agent.
      omit_hostname = false;
    };

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
        urls = [ "https://influxdb.benwolsieffer.com:8086" ]; # required
        ## The target database for metrics (telegraf will create it if not exists).
        database = "telegraf"; # required

        ## Name of existing retention policy to write to.  Empty string writes to
        ## the default retention policy.
        retention_policy = "";
        ## Write consistency (clusters only), can be: "any", "one", "quorum", "all"
        write_consistency = "any";

        ## Write timeout (for the InfluxDB client), formatted as a string.
        ## If not provided, will default to 5s. 0s means no timeout (not recommended).
        timeout = "5s";
        ## Set the user agent for HTTP POSTs (can be useful for log differentiation)
        user_agent = "${ config.networking.hostName }:telegraf";
        ## Set UDP payload size, defaults to InfluxDB UDP Client default (512 bytes)
        # udp_payload = 512

        ## Optional SSL Config
        ssl_cert = ../../machines + "/${config.networking.hostName}/telegraf/client.pem";
        ssl_key = secrets.getSecret secrets."${config.networking.hostName}".telegraf.sslClientCertificateKey;
        ## Use SSL but skip chain & host verification
        # insecure_skip_verify = false;
      };
    };

    inputs = {

      # Read metrics about cpu usage
      cpu = {
        ## Whether to report per-cpu stats or not
        percpu = true;
        ## Whether to report total system cpu stats or not
        totalcpu = true;
        ## If true, collect raw CPU time metrics.
        collect_cpu_time = false;
      };

      # Read metrics about disk usage by mount point
      disk = {
        interval = "5m";
        ## By default, telegraf gather stats for all mountpoints.
        ## Setting mountpoints will restrict the stats to the specified mountpoints.
        # mount_points = ["/"];

        ## Ignore some mountpoints by filesystem type. For example (dev)tmpfs (usually
        ## present on /run, /var/run, /dev/shm or /dev).
        ignore_fs = ["tmpfs" "devtmpfs" "devfs"];
      };

      # Read metrics about disk IO by device
      diskio = {
        ## By default, telegraf will gather stats for all devices including
        ## disk partitions.
        ## Setting devices will restrict the stats to the specified devices.
        devices = ["mmcblk1" "sda"];
        ## Uncomment the following line if you need disk serial numbers.
        # skip_serial_number = false
        #
        ## On systems which support it, device metadata can be added in the form of
        ## tags.
        ## Currently only Linux is supported via udev properties. You can view
        ## available properties for a device by running:
        ## 'udevadm info -q property -n /dev/sda'
        # device_tags = ["ID_FS_TYPE" "ID_FS_USAGE"];
        #
        ## Using the same metadata source as device_tags, you can also customize the
        ## name of the device via templates.
        ## The 'name_templates' parameter is a list of templates to try and apply to
        ## the device. The template may contain variables in the form of '$PROPERTY' or
        ## '${PROPERTY}'. The first template which does not contain any variables not
        ## present for the device is used as the device name tag.
        ## The typical use case is for LVM volumes, to get the VG/LV name instead of
        ## the near-meaningless DM-0 name.
        # name_templates = ["$ID_FS_LABEL" "$DM_VG_NAME/$DM_LV_NAME"];
      };

      # Read metrics about memory usage
      mem = {};

      # Get the number of processes and group them by status
      processes = {};

      # Read metrics about system load & uptime
      system = {};

      # Read metrics about network interface usage
      net = {
        ## By default, telegraf gathers stats from any up interface (excluding loopback)
        ## Setting interfaces will tell it to gather these explicit interfaces,
        ## regardless of status.
        ##
        # interfaces = ["vpn0" "vpn1" "br0"];
      };

      # Read TCP metrics such as established, time wait and sockets counts.
      netstat = {};
    };
  };

  environment.secrets = secrets.mkSecret secrets."${config.networking.hostName}".telegraf.sslClientCertificateKey { user = "telegraf"; };
}
