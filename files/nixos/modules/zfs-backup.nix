{ config, pkgs, ... }: {
  imports = [
    ./zfs.nix
    ./services/backup/sanoid.nix
  ];

  services.sanoid = {
    enable = true;
    datasets = {
      root = {
        useTemplate = [ "local" ];
        recursive = true;
        processChildrenOnly = true;
      };
    };
    templates = {
      local = {
        hourly = 48;
        daily = 60;
        monthly = 12;
        yearly = 0;

        autosnap = true;
        autoprune = true;
      };

      default = {
        minPercentFree = 20;
      };
    };
  };
}