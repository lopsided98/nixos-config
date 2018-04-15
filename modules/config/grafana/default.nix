{ config, lib, secrets, pkgs, ... }: let
  socketDir = "/var/run/grafana";
  socket = "${socketDir}/grafana.sock";
in {
  imports = [
    ../nginx.nix
  ];

  services.grafana = {
    enable = true;

    protocol = "socket";
    domain = "grafana.benwolsieffer.com";
    rootUrl = "https://%(domain)s/";

    extraOptions."SERVER_SOCKET" = socket;

    certFile = builtins.toString ./server.pem;
    certKey = secrets.getSecret secrets.grafana.sslCertificateKey;
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

  users.extraGroups.grafana.gid = 196;

  services.nginx.virtualHosts."grafana.benwolsieffer.com" = {
    http2 = true;

    forceSSL = true;
    sslCertificate = ./server.pem;
    sslCertificateKey = secrets.getSecret secrets.grafana.sslCertificateKey;

    locations."/".proxyPass = "http://unix:${socket}";
  };

  environment.secrets = secrets.mkSecret secrets.grafana.sslCertificateKey { user = "grafana"; };
}
