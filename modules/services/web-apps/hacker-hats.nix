{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hackerHats;

  cfgFile = pkgs.writeText "HackerHats.cfg" ''
    with open('${cfg.secretKeyFile}', 'r') as passwd_file:
        SECRET_KEY = passwd_file.read().strip('\r\n')
    DATABASE = '/var/lib/hacker-hats/data.db'
  '';
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

    secretKeyFile = mkOption {
      type = types.str;
      description = "File containing the secret key.";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    services.hackerHats.uwsgiSocket = mkDefault "${config.services.uwsgi.runDir}/HackerHats.sock";

    services.uwsgi = {
      enable = true;
      user = "nginx";
      group = "nginx";
      plugins = [ "python3" ];
      instance = {
        type = "emperor";
        vassals.hacker-hats = {
          type = "normal";
          pythonPackages = self: with self; [ flask ];
          env = [
            "HACKER_HATS_SETTINGS=${cfgFile}"
          ];
          socket = cfg.uwsgiSocket;
          chdir = pkgs.hacker-hats;
          module = "runserver";
          callable = "app";
        };
      };
    };

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
