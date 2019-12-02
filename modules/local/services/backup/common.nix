{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.backup.common;
in {
  options.local.services.backup.common.enable = mkEnableOption "backup server";

  config = mkIf cfg.enable {
    users.groups.backup.gid = 994;
    users.users.backup = {
      description = "Backup user";
      isSystemUser = true;
      home = "/var/lib/backup";
      group = "backup";
      uid = 994;
    };
  };
}
