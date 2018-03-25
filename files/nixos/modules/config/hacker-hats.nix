{ config, lib, pkgs, ... }: let
  
  secrets = import ../../secrets;
  
  cfgFile = pkgs.writeText "HackerHats.cfg" ''
    with open('/etc/secrets/hacker-hats/secret.key', 'r') as passwd_file:
        SECRET_KEY = passwd_file.read().strip('\r\n')
    DATABASE = '/var/lib/hacker-hats/data.db'
  '';
in {

  imports = [
    ./nginx.nix
    ../services/web-apps/hacker-hats.nix
  ];

  services.hacker-hats.enable = true;
  services.uwsgi = {
    enable = true;
    user = "nginx";
    group = "nginx";
    plugins = [ "python3" ];
    instance = {
      type = "emperor";
      vassals = {
        hacker-hats = {
          type = "normal";
          pythonPackages = self: with self; [ flask ];
          socket = "${config.services.uwsgi.runDir}/HackerHats.sock";
          chdir = "${pkgs.hacker-hats}";
          module = "runserver";
          callable = "app";
          env = [ "HACKER_HATS_SETTINGS=${cfgFile}" ];
        };
      };
    };
  };
  # Configure hostname and SSL
  services.nginx = {
    virtualHosts."${config.services.hacker-hats.virtualHost}" = {
      serverName = "hackerhats.benwolsieffer.com";
      enableACME = true;
      forceSSL = true;
    };
  };
  
  environment.secrets = 
    secrets.mkSecret "hacker-hats/secret.txt" { user = "nginx"; };
}
