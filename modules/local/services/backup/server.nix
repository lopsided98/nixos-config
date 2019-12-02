{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.backup.server;
in {
  options.local.services.backup.server = {
    enable = mkEnableOption "backup server";

    device = mkOption {
      type = types.str;
      description = ''
        Backup drive device to decrypt.
      '';
    };
  };

  config = mkIf cfg.enable {
    local.services.backup = {
      common.enable = true;
      syncthing.enable = true;
    };

    boot.supportedFilesystems = [ "zfs" ];

    # Backup drive decryption prompt
    environment.interactiveShellInit = let
      backupUtils = pkgs.writeText "backup-utils.sh" ''
        backup_decrypted() {
          [ -b /dev/mapper/backup ]
        }

        backup_mounted() {
          zpool list -H | grep -q backup
        }
      '';
      mountBackup = pkgs.writeScript "mount-backup.sh" ''
        #!${pkgs.runtimeShell} -e
        source '${backupUtils}'

        if ! backup_decrypted; then
	        '${pkgs.cryptsetup}/bin/cryptsetup' luksOpen '${cfg.device}' backup
        fi

        if ! backup_mounted; then
          # Use version that matches the kernel module
	        /run/booted-system/sw/bin/zpool import -d /dev/disk/by-id backup
        fi
      '';
    in ''
      (
      source '${backupUtils}'

      yes_no() {
        read -p "$1" choice
        case "$choice" in
          y|Y|[yY][eE][sS] ) return 0;;
          * ) return 1;;
        esac
      }

      if !(backup_decrypted && backup_mounted); then
	      if yes_no "Backup drive is not mounted. Do you want to mount it? (y/N) "; then
		      sudo '${mountBackup}'
	      fi
      fi
      )
    '';

    users.users.backup = {
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQYJwUP/dvd3jFA/F1XFRfScPlraZf3jodYWanb44je" # Dell-Optiplex-780
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9m160Ia27+V9i29j3feDzN/Xp6wabKeAR273LkgjGj backup@HP-Z420"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZXFj+YKXOM5IjChnSbn7vVMwZDup/+eoBEHJJYvf82 backup@Rock64"
      ];
      packages = [ pkgs.lzop pkgs.mbuffer ];
    };
  };
}
