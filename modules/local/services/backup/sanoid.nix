{ config, lib, pkgs, secrets, ... }: let
  cfg = config.local.services.backup.sanoid;
in {
  options.local.services.backup.sanoid.enable = lib.mkEnableOption "Sanoid ZFS backup";

  config = lib.mkIf cfg.enable {
    boot.supportedFilesystems = [ "zfs" ];

    services.sanoid = {
      enable = true;
      templates = {
        # Local snapshots of /nix and other easily replaceable data
        system = {
          hourly = 24;
          daily = 5;
          monthly = 1;
          yearly = 0;

          autosnap = true;
          autoprune = true;
        };

        # Local snapshots of irreplaceable data
        data = {
          hourly = 48;
          daily = 10;
          monthly = 1;
          yearly = 1;

          autosnap = true;
          autoprune = true;
        };

        # Backups of irreplaceable data
        backup = {
          hourly = 48;
          daily = 60;
          monthly = 24;
          yearly = 10;

          autosnap = false;
          autoprune = true;
        };

        # Backups of /nix and other easily replaceable data
        backup-system = {
          hourly = 48;
          daily = 60;
          monthly = 3;
          yearly = 0;
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
