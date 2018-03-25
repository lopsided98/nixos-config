{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hacker-hats;
  
in {

  # Interface

  options.services.hacker-hats = {
    enable = mkEnableOption "HackerHats website";
    
    virtualHost = mkOption {
      type = types.nullOr types.str;
      default = "hacker-hats";
      description = ''
        Name of the nginx virtualhost to use and setup. If null, do not setup 
        any virtualhost.
      '';
    };
    
    uwsgiSocket = mkOption {
      type = types.str;
      default = "${config.services.uwsgi.runDir}/HackerHats.sock";
      description = ''
        Socket file used to communicate between nginx and uwsgi.
      '';
    };
  };
  
  # Implementation
  
  config = mkIf cfg.enable {
    services.nginx.enable = true;
    services.nginx.virtualHosts = mkIf (cfg.virtualHost != null) {
      "${cfg.virtualHost}" = {
        locations = {
          "/" = {
            tryFiles = "$uri @HackerHats";
          };
        
          "@HackerHats" = {
            extraConfig = ''
              uwsgi_pass unix:${cfg.uwsgiSocket};
            '';
          };
        
          "/static/" = {
            root = "${pkgs.hacker-hats}/HackerHats";
          };
        
          "/favicon.ico" = {
            alias = "${pkgs.hacker-hats}/HackerHats/static/img/favicons/favicon.ico";
          };
        };
      };
    };
  };
}
