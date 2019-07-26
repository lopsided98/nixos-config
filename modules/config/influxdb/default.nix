{ lib, config, secrets, pkgs, ... }: with lib; let
  socketDir = "/run/influxdb";
  socket = "${socketDir}/influxdb.sock";
  influxdbPort = 8086;
in {

  services.influxdb = {
    enable = true;
    extraConfig = {
      reporting-disabled = true;
      http = {
        auth-enabled = true;
        log-enabled = false;
        bind-address = "";
        unix-socket-enabled = true;
        bind-socket = socket;
      };
      # Disable collectd because I don't use it and it does not currently build
      collectd = [];
    };
  };

  # Setup influxdb socket permissions
  systemd.tmpfiles.rules = let cfg = config.services.influxdb; in [
    "d '${socketDir}' 0750 ${cfg.user} ${cfg.group} - -"
    "a '${socketDir}' - - - - u:nginx:rx"
  ];

  systemd.services.influxdb.postStart = mkForce ''
    # Wait for socket to be created
    while [ ! -S "${socket}" ]; do sleep 1; done
  '';

  services.nginx = {
    enable = true;
    virtualHosts.influxdb = {
      http2 = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = influxdbPort;
          ssl = true;
        }
        {
          addr = "[::]";
          port = influxdbPort;
          ssl = true;
        }
      ];

      addSSL = true;
      sslCertificate = ./server.pem;
      sslCertificateKey = secrets.getSecret secrets.influxdb.sslCertificateKey;

      locations."/" = {
        proxyPass = "http://unix:${socket}";
        
        extraConfig = ''
          proxy_set_header Authorization "Basic $influxdb_authorization";
        '';
      };

      extraConfig = ''
        access_log off;

        ssl_client_certificate ${./client_ca.pem};
        ssl_crl ${./client_ca_crl.pem};
        ssl_verify_client on;
      '';
    };

    appendHttpConfig = ''
      # Get username from the organization field of the client certificate
      map $ssl_client_s_dn $influxdb_username {
        "~O=(?<u>[^,]+)(,|$)" $u;
      }

      # If the certificate organization field contains an allowed username, 
      # automatically authenticate that user. Otherwise, pass the basic auth
      # header through.
      map $influxdb_username $influxdb_authorization {
        include ${secrets.getSecret secrets.influxdb.passwordMap};
      }
    '';
  };

  environment.secrets = 
    secrets.mkSecret secrets.influxdb.sslCertificateKey { user = "nginx"; } //
    secrets.mkSecret secrets.influxdb.passwordMap { user = "nginx"; };
}
