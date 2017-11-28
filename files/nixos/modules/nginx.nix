{ services, ... }:

{
  services.nginx = {
    enable = true;
    commonHttpConfig = ''
      log_format access '[$host] $remote_addr "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log syslog:server=unix:/dev/log,nohostname,tag= access;
    '';
  };
}
