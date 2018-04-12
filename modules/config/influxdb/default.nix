{ lib, config, secrets, ... }: with lib; let
  influxdbSocketDir = "/var/run/influxdb";
  influxdbSocket = "${influxdbSocketDir}/influxdb.sock";
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
        bind-socket = influxdbSocket;
      };
    };
  };
  
  # Setup influxdb socket permissions
  systemd.services.influxdb = {
    preStart = ''
      # Setup socket directory
      mkdir -p "${influxdbSocketDir}"
      chmod 0750 "${influxdbSocketDir}"
      chown ${config.services.influxdb.user}:${config.services.influxdb.group} "${influxdbSocketDir}"
      # Setup data directory
      mkdir -p "${config.services.influxdb.dataDir}"
      chmod 0750 "${config.services.influxdb.dataDir}"
      chown ${config.services.influxdb.user}:${config.services.influxdb.group} "${config.services.influxdb.dataDir}"
    '';
    postStart = mkForce ''
      # Wait for socket to be created
      while [ ! -S "${influxdbSocket}" ]; do
        sleep 1
      done
      # Make socket writable by nginx
      chmod 0660 "${influxdbSocket}"
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
        proxyPass = "http://unix:${influxdbSocket}";
        
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
  
  # Add nginx to the influxdb group so it can access the socket
  users.extraUsers.nginx = {
    extraGroups = [ config.services.influxdb.group ];
  };
  
  environment.secrets = 
    secrets.mkSecret secrets.influxdb.sslCertificateKey { user = "nginx"; } //
    secrets.mkSecret secrets.influxdb.passwordMap { user = "nginx"; };
}
