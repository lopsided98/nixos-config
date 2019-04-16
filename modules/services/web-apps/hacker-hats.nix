{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hackerHats;

in {

  # Interface

  options.services.hackerHats = {
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
      description = ''
        Socket file used to communicate between nginx and uwsgi.
      '';
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    services.hackerHats.uwsgiSocket = mkDefault "${config.services.uwsgi.runDir}/HackerHats.sock";

    services.nginx = mkIf (cfg.virtualHost != null) {
      enable = true;
      virtualHosts = {
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

            "= /favicon.ico" = {
              alias = "${pkgs.hacker-hats}/HackerHats/static/img/favicons/favicon.ico";
            };
          };
        };
      };
    };
  };
}
