{ config, lib, secrets, ... }: {
  services.grafana = {
    enable = true;
    
    protocol = "https";
    addr = "0.0.0.0";
    domain = "grafana.benwolsieffer.com";
    
    certFile = builtins.toString ./server.pem;
    certKey = secrets.getSecret secrets.grafana.sslCertificateKey;
  };
  
  networking.firewall.allowedTCPPorts = [ config.services.grafana.port ];
  
  environment.secrets = secrets.mkSecret secrets.grafana.sslCertificateKey { user = "grafana"; };
}
