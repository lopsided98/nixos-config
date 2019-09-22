{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.deluge;
in {
  options.local.services.deluge = {
    enable = mkEnableOption "Deluge torrent client";

    downloadDir = mkOption {
      type = types.str;
      default = "/mnt/backup/data/torrents";
      description = ''
        Directory to store downloaded files.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;

      declarative = true;
      config = {
        download_location = cfg.downloadDir;
        random_port = false;
        listen_ports = [ 62761 62769 ];
      };
      authFile = secrets.getSecret secrets.deluge.authFile;

      openFirewall = true;
    };

    environment.secrets = secrets.mkSecret secrets.deluge.authFile {
      inherit (config.services.deluge) user group;
    };
  };
}
