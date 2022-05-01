{ config, lib, secrets, pkgs, ... }: let
  socketDir = "/var/run/grafana";
  socket = "${socketDir}/grafana.sock";
in {
  services.grafana = {
    enable = true;

    protocol = "socket";
    socket = socket;
    domain = "grafana.benwolsieffer.com";
    rootUrl = "https://%(domain)s/";

    smtp = {
      enable = true;
      host = "smtp.gmail.com:465";
      user = "benwolsieffer@gmail.com";
      passwordFile = secrets.getSystemdSecret "grafana" secrets.grafana.gmailPassword;
      fromAddress = "grafana@benwolsieffer.com";
    };

    # Enable XYChart
    extraOptions.PANELS_ENABLE_ALPHA = "true";
  };

  systemd.services.grafana = {
    path = [ pkgs.acl ];
    serviceConfig = {
      Group = "grafana";
      PermissionsStartOnly = true;
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
    virtualHosts."grafana.benwolsieffer.com" = {
      http2 = true;

      forceSSL = true;
      sslCertificate = ./server.pem;
      sslCertificateKey = secrets.getSystemdSecret "grafana" secrets.grafana.sslCertificateKey;

      locations."/".proxyPass = "http://unix:${socket}";
    };
  };

  systemd.secrets.grafana = {
    files = lib.mkMerge [
      (secrets.mkSecret secrets.grafana.sslCertificateKey { user = "nginx"; })
      (secrets.mkSecret secrets.grafana.gmailPassword { user = "grafana"; })
    ];
    units = [ "grafana.service" ];
  };
}
