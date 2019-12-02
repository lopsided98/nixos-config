{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.backup.sanoid;
in {
  options.local.services.backup.sanoid.enable = mkEnableOption "Sanoid ZFS backup";

  config = mkIf cfg.enable {
    local.services.backup.common.enable = true;

    boot.supportedFilesystems = [ "zfs" ];

    services.sanoid = {
      enable = true;
      templates = {
        local = {
          hourly = 48;
          daily = 10;
          monthly = 1;
          yearly = 1;

          autosnap = true;
          autoprune = true;
        };

        backup = {
          hourly = 48;
          daily = 60;
          monthly = 24;
          yearly = 10;

          autosnap = false;
          autoprune = true;
        };
      };
      extraArgs = [ "--verbose" ];
    };
    services.syncoid = {
      enable = true;
      interval = "*-*-* *:15:00";
      user = "backup";
      sshKey = secrets.getSecret secrets."${config.networking.hostName}".backup.sshKey;
      commonArgs = [ "--no-privilege-elevation" "--no-sync-snap" ];
    };
    systemd = {
      notifyFailed.enable = true;
      services = {
        sanoid.notifyFailed = true;
        syncoid = {
          # Hack to ignore all exit codes except the last because some of the
          # commands return an error because there are no snapshots for a parent
          # dataset.
          script = lib.mkBefore "set +e";
          notifyFailed = true;
        };
      };
      # Prevent syncoid on multiple machines from running at the same time and
      # failing with "<dataset> is already target of a zfs receive process."
      timers.syncoid.timerConfig.RandomizedDelaySec = "10m";
    };

    environment.secrets = secrets.mkSecret secrets."${config.networking.hostName}".backup.sshKey { user = "backup"; };
  };
}
