{ config, lib, pkgs, secrets, ... }: with lib; let 
  cfg = config.modules.syncthingBackup;
  sslCertificateKey = secrets.getSecret cfg.sslCertificateKeySecret;
in {
  options.modules.syncthingBackup = {
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
      default = ../../../machines + "/${config.networking.hostName}/syncthing/server.pem";
      description = "SSL certificate to use for Syncthing and nginx";
    };

    sslCertificateKeySecret = mkOption {
      type = types.str;
      default = secrets."${config.networking.hostName}".syncthing.sslCertificateKey;
      description = "SSL certificate key to use for Syncthing and nginx";
    };
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openDefaultPorts = true;
      dataDir = "${cfg.backupMountpoint}/syncthing";
    };

    # Increase inotify watch limit
    boot.kernel.sysctl."fs.inotify.max_user_watches" = 204800;

    systemd.services.syncthing = {
      unitConfig.ConditionPathIsMountPoint = cfg.backupMountpoint;
      preStart = ''
        # Install SSL certificates
        install -o ${cfg.user} -g ${cfg.group} -m 0400 "${sslCertificateKey}" "${config.services.syncthing.dataDir}/https-key.pem"
        install -o ${cfg.user} -g ${cfg.group} -m 0644 "${cfg.sslCertificate}" "${config.services.syncthing.dataDir}/https-cert.pem"
      '';
    };

    services.nginx.virtualHosts."${cfg.virtualHost}" = {
      http2 = true;

      forceSSL = true;
      sslCertificate = cfg.sslCertificate;
      sslCertificateKey = sslCertificateKey;

      locations."/".proxyPass = "https://localhost:8384";

      extraConfig = ''
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        proxy_ssl_trusted_certificate "${cfg.sslCertificate}";
        # TODO: figure out elegant way to verify certificate
        proxy_ssl_verify off;
      '';
    };

    environment.secrets = secrets.mkSecret cfg.sslCertificateKeySecret { user = cfg.user; };
  };
}
