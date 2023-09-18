{ config, lib, pkgs, secrets, ... }: let
  cfg = config.local.services.backup.syncthing;
in {
  options.local.services.backup.syncthing = {
    enable = lib.mkEnableOption "Syncthing backup synchronization";

    virtualHost = lib.mkOption {
      type = lib.types.str;
      description = "Name of the nginx virtual host";
    };

    backupMountpoint = lib.mkOption {
      type = lib.types.str;
      description = "Path where the backup drive is mounted";
    };

    certificate = lib.mkOption {
      type = lib.types.path;
      description = "Certificate to use for Syncthing protocol";
    };

    certificateKeySecret = lib.mkOption {
      type = lib.types.str;
      description = "Certificate key to use for Syncthing protocol";
    };

    httpsCertificate = lib.mkOption {
      type = lib.types.path;
      description = "Certificate to use for Syncthing web interface";
    };

    httpsCertificateKeySecret = lib.mkOption {
      type = lib.types.str;
      description = "Certificate key to use for Syncthing web interface";
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.backup-syncthing = {
        description = "Syncthing backup user";
        isSystemUser = true;
        home = config.services.syncthing.configDir;
        group = "backup-syncthing";
        uid = 994;
      };
      groups.backup-syncthing.gid = 994;
    };

    services.syncthing = {
      enable = true;
      user = "backup-syncthing";
      group = "backup-syncthing";
      openDefaultPorts = true;
      dataDir = cfg.backupMountpoint;
      configDir = "${cfg.backupMountpoint}/syncthing";
      cert = "${cfg.certificate}";
      key = secrets.getSystemdSecret "syncthing" cfg.certificateKeySecret;
    };

    # Increase inotify watch limit
    boot.kernel.sysctl."fs.inotify.max_user_watches" = 5000000;

    systemd.services.syncthing.unitConfig.ConditionPathIsMountPoint = cfg.backupMountpoint;

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.virtualHost} = {
        http2 = true;

        forceSSL = true;
        sslCertificate = cfg.httpsCertificate;
        sslCertificateKey = secrets.getSystemdSecret "syncthing-nginx" cfg.httpsCertificateKeySecret;

        locations."/".proxyPass = "https://localhost:8384";

        extraConfig = ''
          proxy_read_timeout 600s;
          proxy_send_timeout 600s;
          proxy_ssl_trusted_certificate "${cfg.httpsCertificate}";
          # TODO: figure out elegant way to verify certificate
          proxy_ssl_verify off;
        '';
      };
    };

    systemd.secrets = {
      syncthing = {
        units = [ "syncthing.service" ];
        files = secrets.mkSecret cfg.certificateKeySecret {  };
      };
      syncthing-nginx = {
        units = [ "nginx.service" ];
        files = secrets.mkSecret cfg.httpsCertificateKeySecret {
          inherit (config.services.nginx) user;
        };
      };
    };
  };
}
