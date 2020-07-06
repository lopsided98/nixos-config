{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.local.services.publicFiles;
in {
  options.local.services.publicFiles = {
    enable = mkEnableOption "web server for public files";

    uploadUser = mkOption {
      type = types.str;
      default = "ben";
      description = "User with permission to write files";
    };

    virtualHost = mkOption {
      type = types.str;
      default = "files.benwolsieffer.com";
      description = "Web server domain name";
    };

    filesDir = mkOption {
      type = types.str;
      default = "/var/lib/public";
      description = "Directory containing files";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.public-files = {
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p '${cfg.filesDir}'
        chown '${cfg.uploadUser}:${config.services.nginx.group}' '${cfg.filesDir}'
        chmod u=rwx,g=srx,o=rx '${cfg.filesDir}'
      '';
      wantedBy = [ "nginx.service" ];
      before = [ "nginx.service" ];
    };
  
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.virtualHost} = {
        enableACME = true;
        forceSSL = true;
        locations."/".root = cfg.filesDir;
      };
    };
  };
}
