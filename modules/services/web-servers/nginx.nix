{ config, lib, pkgs, ... }:

{
  services.nginx = lib.mkIf config.services.nginx.enable {
    package = pkgs.nginxMainline;
    commonHttpConfig = ''
      log_format access '[$host] $remote_addr "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log syslog:server=unix:/dev/log,nohostname,tag= access;
      error_log stderr info;
      
      client_body_buffer_size 1M;
    '';
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
