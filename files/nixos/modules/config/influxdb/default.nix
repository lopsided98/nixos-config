{ lib, config, secrets, ... }: with lib; let
  influxdbSocket = "/var/run/influxdb/influxdb.sock";
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
      mkdir -m 0750 -p /var/run/influxdb
      chown ${config.services.influxdb.user}:${config.services.influxdb.group} /var/run/influxdb
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
      sslCertificate = ./influxdb.pem;
      sslCertificateKey = secrets.getSecret secrets.influxdb.sslCertificateKey;
      
      locations."/" = {
        proxyPass = "http://unix:${influxdbSocket}";
      };
      
      extraConfig = ''
        access_log off;

        #proxy_set_header "Authorization: Basic $authorization";
      '';
    };
    
    appendHttpConfig = ''
      # Get username from the organization field of the client certificate
      map $ssl_client_s_dn $username {
        "~O=(?<u>[^,]+)(,|$)" $u;
      }
      
      # These passwords are not really secret, because the connection between
      # nginx and influxdb is already secured by the filesystem permissions 
      # of the unix socket.
      map $username $authorization {
        "telegraf" "dGVsZWdyYWY6Wk9NbkhxbGVnYUttRUxaSndzTU0K";
        "grafana" "Z3JhZmFuYTpwcWNZT0tTVk5ka0xNbUl2S3RTTwo=";
      }
    '';
  };
  
  # Add nginx to the influxdb group so it can access the socket
  users.extraUsers.nginx = {
    extraGroups = [ config.services.influxdb.group ];
  };
  
  environment.secrets = secrets.mkSecret secrets.influxdb.sslCertificateKey { user = "nginx"; };
}
