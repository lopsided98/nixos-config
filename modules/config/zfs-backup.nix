{ config, pkgs, secrets, ... }: {

  # Enable ZFS
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
    extraArgs = "--verbose";
  };
  services.syncoid = {
    enable = true;
    interval = "*-*-* *:15:00";
    user = "backup";
    sshKey = secrets.getSecret secrets."${config.networking.hostName}".backup.sshKey;
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZXFj+YKXOM5IjChnSbn7vVMwZDup/+eoBEHJJYvf82 backup@Rock64"
    ];
    packages = [ pkgs.lzop pkgs.mbuffer ];
  };
  
  environment.secrets = secrets.mkSecret secrets."${config.networking.hostName}".backup.sshKey { user = "backup"; };
}
