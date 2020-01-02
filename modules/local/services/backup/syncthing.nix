{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.backup.syncthing;
  sslCertificateKeySecret = secrets."${config.networking.hostName}".syncthing.sslCertificateKey;
in {
  options.local.services.backup.syncthing = {
    enable = mkEnableOption "Syncthing backup synchronization";

    virtualHost = mkOption {
      type = types.str;
      description = "Name of the nginx virtual host";
    };

    user = mkOption {
      type = types.str;
      default = "backup";
      description = "Syncthing user";
    };

    group = mkOption {
      type = types.str;
      default = "backup";
      description = "Syncthing group";
    };

    backupMountpoint = mkOption {
      type = types.str;
      default = "/mnt/backup";
      description = "Path where the backup drive is mounted";
    };

    sslCertificate = mkOption {
      type = types.path;
      description = "SSL certificate to use for Syncthing and nginx";
    };

    sslCertificateKey = mkOption {
      type = types.str;
      description = "SSL certificate key to use for Syncthing and nginx";
    };
  };

  config = mkIf cfg.enable {

    local.services.backup.syncthing = {
      sslCertificate = mkDefault (../../../../machines + "/${config.networking.hostName}/syncthing/server.pem");
      sslCertificateKey = mkDefault (secrets.getSecret sslCertificateKeySecret);
    };

    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openDefaultPorts = true;
      dataDir = "${cfg.backupMountpoint}";
      configDir = "${cfg.backupMountpoint}/syncthing";
    };

    # Increase inotify watch limit
    boot.kernel.sysctl."fs.inotify.max_user_watches" = 204800;

    systemd.services.syncthing.unitConfig.ConditionPathIsMountPoint = cfg.backupMountpoint;

    services.nginx = {
      enable = true;
      virtualHosts."${cfg.virtualHost}" = {
        http2 = true;

        forceSSL = true;
        sslCertificate = cfg.sslCertificate;
        sslCertificateKey = cfg.sslCertificateKey;

        locations."/".proxyPass = "https://localhost:8384";

        extraConfig = ''
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          proxy_ssl_trusted_certificate "${cfg.sslCertificate}";
          # TODO: figure out elegant way to verify certificate
          proxy_ssl_verify off;
        '';
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 ];
    };

    environment.secrets = secrets.mkSecret sslCertificateKeySecret { inherit (config.services.nginx) user; };
  };
}
