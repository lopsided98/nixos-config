{ config, lib, pkgs, secrets, ... }: with lib; let
  cfgFile = pkgs.writeText "HackerHats.cfg" ''
    with open('${secrets.getSecret secrets.hackerHats.secretKey}', 'r') as passwd_file:
        SECRET_KEY = passwd_file.read().strip('\r\n')
    DATABASE = '/var/lib/hacker-hats/data.db'
  '';
in {

  services.hacker-hats.enable = true;
  services.uwsgi = {
    enable = true;
    user = "nginx";
    group = "nginx";
    plugins = [ "python3" ];
    type = "emperor";
    vassals = {
      hacker-hats = {
        pythonPackages = self: with self; [ flask ];
        env = {
          HACKER_HATS_SETTINGS = cfgFile;
        };
        extraConfig = {
          socket = "${config.services.uwsgi.runDir}/HackerHats.sock";
          chdir = "${pkgs.hacker-hats}";
          module = "runserver";
          callable = "app";
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
  
  environment.secrets = secrets.mkSecret secrets.hackerHats.secretKey { user = "nginx"; };
}
