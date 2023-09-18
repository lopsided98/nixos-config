{ config, lib, pkgs, secrets, ... }: let
  cfg = config.local.services.backup.server;
in {
  options.local.services.backup.server = {
    enable = lib.mkEnableOption "backup server";

    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Backup drive devices";
    };
  };

  config = lib.mkIf cfg.enable {
    local.services.backup.syncthing.enable = true;

    boot.supportedFilesystems = [ "zfs" ];

    local.services.mail.enable = true;

    services.smartd = {
      enable = true;
      autodetect = false;
      extraOptions = [ "--interval=43200" /* 12h */ ];

      notifications.mail = {
        enable = true;
        sender = "${config.networking.hostName}@benwolsieffer.com";
        recipient = "benwolsieffer@gmail.com";
        mailer = config.local.services.mail.sendmail;
      };

      defaults.monitored = "-H -f -l error -l selftest -C 197 -U 198";
      devices = builtins.map (device: { inherit device; }) cfg.devices;
    };

    users = {
      users.backup = {
        description = "Backup user";
        isSystemUser = true;
        home = "/var/lib/backup";
        group = "backup";
        uid = 800;
        shell = pkgs.bash;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9m160Ia27+V9i29j3feDzN/Xp6wabKeAR273LkgjGj backup@HP-Z420"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZXFj+YKXOM5IjChnSbn7vVMwZDup/+eoBEHJJYvf82 backup@Rock64"
        ];
        packages = [ pkgs.lzop pkgs.mbuffer ];
      };
      groups.backup.gid = 800;
    };
  };
}
