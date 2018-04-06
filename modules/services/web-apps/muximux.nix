{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.muximux;
  
  poolName = "muximux";
  phpfpmSocketName = "/var/run/phpfpm/${poolName}.sock";
  
in {

  # Interface

  options.services.muximux = {
    enable = mkEnableOption "Muximux HTPC management portal";
    
    pool = mkOption {
      type = types.str;
      default = "${poolName}";
      description = ''
        Name of existing phpfpm pool that is used to run web-application.
        If not specified a pool will be created automatically with
        default values.
      '';
    };
    
    virtualHost = mkOption {
      type = types.nullOr types.str;
      default = "muximux";
      description = ''
        Name of the nginx virtualhost to use and setup. If null, do not setup any virtualhost.
      '';
    };
  };
  
  # Implementation
  
  config = mkIf cfg.enable {
  
    services.phpfpm.poolConfigs = mkIf (cfg.pool == "${poolName}") {
      "${poolName}" = ''
        listen = "${phpfpmSocketName}";
        listen.owner = ${config.services.nginx.user}
        listen.group = ${config.services.nginx.user}
        listen.mode = 0600
        user = ${config.services.nginx.user}
        pm = dynamic
        pm.max_children = 75
        pm.start_servers = 10
        pm.min_spare_servers = 5
        pm.max_spare_servers = 20
        pm.max_requests = 500
        catch_workers_output = 1
      '';
    };
  
    services.nginx.enable = true;
    services.nginx.virtualHosts = mkIf (cfg.virtualHost != null) {
      "${cfg.virtualHost}" = {
        root = "${pkgs.muximux}";
        locations."/" = {
          index = "index.php";
        };
        
        locations."~ \.php$" = {
          extraConfig = ''
            try_files $uri $document_root$fastcgi_script_name =404;
            fastcgi_pass unix:${phpfpmSocketName};
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include ${pkgs.nginx}/conf/fastcgi_params;
          '';
        };
      };
    };
  };
}
