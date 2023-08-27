{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.services.backup.syncthing;
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
      description = "Path where the backup drive is mounted";
    };

    certificate = mkOption {
      type = types.path;
      description = "Certificate to use for Syncthing protocol";
    };

    certificateKeySecret = mkOption {
      type = types.str;
      description = "Certificate key to use for Syncthing protocol";
    };

    httpsCertificate = mkOption {
      type = types.path;
      description = "Certificate to use for Syncthing web interface";
    };

    httpsCertificateKeySecret = mkOption {
      type = types.str;
      description = "Certificate key to use for Syncthing web interface";
    };
  };

  config = mkIf cfg.enable {

    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      openDefaultPorts = true;
      dataDir = "${cfg.backupMountpoint}";
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

    networking.firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 ];
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
