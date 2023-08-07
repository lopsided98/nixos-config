{ lib, secrets, ... }: let
  googleDomains = domain: {
    type = "GoogleDomains";
    args.hostname = domain;
    includeArgs = {
      username = secrets.getSystemdSecret "dnsupdate" secrets.dnsupdate."${domain}".username;
      password = secrets.getSystemdSecret "dnsupdate" secrets.dnsupdate."${domain}".password;
    };
  };
in {
  services.dnsupdate = {
    enable = true;
    addressProvider = {
      ipv4.type = "Web";
    };

    dnsServices = [
      (googleDomains "raspi2.benwolsieffer.com")
      (googleDomains "dell-optiplex-780.benwolsieffer.com")
      (googleDomains "odroid-xu4.benwolsieffer.com")
      (googleDomains "hp-z420.benwolsieffer.com")
      (googleDomains "rock64.benwolsieffer.com")
    ];
  };

  systemd.secrets.dnsupdate = {
    units = [ "dnsupdate.service" ];
    files = lib.mkMerge [
      (secrets.mkSecret secrets.dnsupdate."raspi2.benwolsieffer.com".username { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."raspi2.benwolsieffer.com".password { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."dell-optiplex-780.benwolsieffer.com".username { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."dell-optiplex-780.benwolsieffer.com".password { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."odroid-xu4.benwolsieffer.com".username { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."odroid-xu4.benwolsieffer.com".password { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."hp-z420.benwolsieffer.com".username { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."hp-z420.benwolsieffer.com".password { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."rock64.benwolsieffer.com".username { user = "dnsupdate"; })
      (secrets.mkSecret secrets.dnsupdate."rock64.benwolsieffer.com".password { user = "dnsupdate"; })
    ];
  };
}
