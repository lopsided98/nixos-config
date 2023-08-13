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
        # Enable Flux query language
        flux-enabled = true;
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

  systemd.services.influxdb = {
    # InfluxDB can take a long time to start
    serviceConfig.TimeoutStartSec = "5 min";
    # Wait for socket to be created. The default postStart only works with
    # HTTP(S).
    postStart = mkForce ''
      until [ -S "${socket}" ]; do sleep 1; done
    '';
  };

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
      sslCertificateKey = secrets.getSystemdSecret "influxdb-nginx" secrets.influxdb.sslCertificateKey;

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
        include ${secrets.getSystemdSecret "influxdb-nginx" secrets.influxdb.passwordMap};
      }
    '';
  };

  systemd.secrets.influxdb-nginx = {
    files = lib.mkMerge [
      (secrets.mkSecret secrets.influxdb.sslCertificateKey { user = "nginx"; })
      (secrets.mkSecret secrets.influxdb.passwordMap { user = "nginx"; })
    ];
    units = [ "nginx.service" ];
  };
}
