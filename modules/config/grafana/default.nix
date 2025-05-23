{ config, lib, secrets, pkgs, ... }: let
  socketDir = "/run/grafana";
  socket = "${socketDir}/grafana.sock";
in {
  services.grafana = {
    enable = true;

    settings = {
      server = {
        protocol = "socket";
        socket = socket;
        domain = "grafana.benwolsieffer.com";
        root_url = "https://%(domain)s/";
      };

      smtp = {
        enabled = true;
        host = "smtp.gmail.com:465";
        user = "benwolsieffer@gmail.com";
        password = "$__file{${secrets.getSystemdSecret "grafana" secrets.grafana.gmailPassword}}";
        from_address = "grafana@benwolsieffer.com";
      };

      # Enable XYChart
      panels.enable_alpha = true;
    };
  };

  systemd.services.grafana = {
    path = [ pkgs.acl ];
    serviceConfig = {
      Group = "grafana";
      PermissionsStartOnly = true;
      # Grafana can take a long time to start
      TimeoutStartSec = "5 min";
    };
    preStart = ''
      # Setup socket directory
      install -o grafana -g grafana -m 0750 -d "${socketDir}"
      setfacl -bm u:nginx:rx "${socketDir}"
      # Setup data directory
      install -o grafana -g grafana -m 0750 -d "${config.services.grafana.dataDir}"
    '';
    postStart = ''
      # Wait for socket to be created
      while [ ! -S "${socket}" ]; do sleep 1; done
      # Make socket writable by nginx
      setfacl -bm u:nginx:rw "${socket}"
    '';
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."grafana.benwolsieffer.com" = {
      http2 = true;

      forceSSL = true;
      sslCertificate = ./server.pem;
      sslCertificateKey = secrets.getSystemdSecret "grafana-nginx" secrets.grafana.sslCertificateKey;

      locations = {
        "/".proxyPass = "http://unix:${socket}";

        "/api/live/" = {
          proxyPass = "http://unix:${socket}";
          proxyWebsockets = true;
        };
      };
    };
  };

  systemd.secrets = {
    grafana = {
      files = secrets.mkSecret secrets.grafana.gmailPassword { user = "grafana"; };
      units = [ "grafana.service" ];
    };
    grafana-nginx = {
      files = secrets.mkSecret secrets.grafana.sslCertificateKey { user = "nginx"; };
      units = [ "nginx.service" ];
    };
  };
}
