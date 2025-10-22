{ config, lib, pkgs, ... }:
let
  cfg = config.local.services.immich;
in {
  options.local.services.immich = {
    enable = mkEnableOption "Immich server";

    virtualHost = mkOption {
      type = types.str;
      default = "photos.benwolsieffer.com";
      description = "Web server domain name";
    };
  };

  config = lib.mkIf cfg.enable {
    services.immich.enable = true;

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.virtualHost} = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${toString config.services.immich.port}";
          proxyWebsockets = true;
          extraConfig = ''
            # Allow only traffic from local network
            ${lib.concatMapStringsSep "\n" (s: "allow ${s};") config.local.networking.home.localSubnets}
            deny all;

            client_max_body_size 50000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
      };
    };
  };
}
