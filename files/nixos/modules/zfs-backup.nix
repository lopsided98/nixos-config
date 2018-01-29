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

        recursive = false;
        autosnap = false;
        autoprune = false;
      };

      default = {
        minPercentFree = 20;
      };
    };
    extraArgs = "--verbose";
  };
  services.syncoid = {
    enable = true;
    interval = "*-*-* *:15:00";
    user = "backup";
    sshKey = "/var/lib/backup/.ssh/id_ed25519";
    defaultArguments = "--no-privilege-elevation --no-sync-snap";
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
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEQYJwUP/dvd3jFA/F1XFRfScPlraZf3jodYWanb44je" # Dell-Optiplex-780
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9m160Ia27+V9i29j3feDzN/Xp6wabKeAR273LkgjGj backup@HP-Z420"
    ];
    packages = [ pkgs.lzop pkgs.mbuffer ];
  };
}
