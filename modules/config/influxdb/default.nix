{ lib, config, secrets, pkgs, ... }: with lib; let
  socketDir = "/var/run/influxdb";
  socket = "${socketDir}/influxdb.sock";
  influxdbPort = 8086;
in {
  imports = [
    ../nginx.nix
  ];

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
    };
  };
  
  # Setup influxdb socket permissions
  systemd.services.influxdb = let cfg = config.services.influxdb; in {
    path = [ pkgs.acl ];
    preStart = ''
      # Setup socket directory
      install -o ${cfg.user} -g ${cfg.group} -m 0750 -d "${socketDir}"
      setfacl -bm u:nginx:rx "${socketDir}"
      # Setup data directory
      install -o ${cfg.user} -g ${cfg.group} -m 0750 -d "${cfg.dataDir}"
    '';
    postStart = mkForce ''
      # Wait for socket to be created
      while [ ! -S "${socket}" ]; do sleep 1; done
      # Make socket writable by nginx
      setfacl -bm u:nginx:rw "${socket}"
    '';
  };
  
  services.nginx = {
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

        ssl_client_certificate ${../common/root_ca.pem};
        ssl_crl ${./client_ca_crl.pem};
        ssl_verify_depth 2;
        ssl_verify_client optional;
        
        if ($ssl_client_i_dn != "CN=InfluxDB Client CA") {
          return 401;
        }
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
