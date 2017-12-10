{ config, pkgs, ... }: {
  imports = [
    ./zfs.nix
    ./services/backup/sanoid.nix
    ./services/backup/syncoid.nix
  ];

  services.sanoid = {
    enable = true;
    templates = {
      local = {
        hourly = 48;
        daily = 60;
        monthly = 12;
        yearly = 0;

        recursive = false;
        autosnap = true;
        autoprune = true;
      };
      
      backup = {
        hourly = 48;
        daily = 60;
        monthly = 24;
        yearly = 10;

        autosnap = false;
        autoprune = false;
      };

      default = {
        minPercentFree = 20;
      };
    };
  };
  services.syncoid = {
    enable = true;
    user = "backup";
    sshKey = "/var/lib/backup/.ssh/id_ed25519";
  };
  
  users.extraGroups.backup = {
    gid = 994;
  };
  users.extraUsers.backup = {
    description = "Backup user";
    isSystemUser = true;
    home = "/var/lib/backup";
    group = "backup";
    uid = 994;
  };
}
