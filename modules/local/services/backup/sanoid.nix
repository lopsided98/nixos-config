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
        system = {
          hourly = 24;
          daily = 5;
          monthly = 1;
          yearly = 0;

          autosnap = true;
          autoprune = true;
        };

        data = {
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
      sshKey = secrets.getSecret secrets."${config.networking.hostName}".backup.sshKey;
      commonArgs = [ "--no-sync-snap" ];
      service.notifyFailed = true;
    };
    systemd = {
      notifyFailed.enable = true;
      services.sanoid.notifyFailed = true;
    };

    environment.secrets = secrets.mkSecret secrets."${config.networking.hostName}".backup.sshKey { user = "syncoid"; };
  };
}
