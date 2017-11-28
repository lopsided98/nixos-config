{ config, pkgs, ... }:

{
  imports = [ ./services/networking/dnsupdate.nix ];

  services.dnsupdate = {
    enable = true;
    addressProvider = {
      ipv4 = {
        type = "Web";
        args = {};
      };
      ipv6 = null;
    };
    
    dnsServices = [ {
      type = "NSUpdate";
      args = {
        hostname = "dnsupdate-test.nsupdate.info";
        secret_key = "Vx7wsrLT7L";
      };
    } ];
  };

}
