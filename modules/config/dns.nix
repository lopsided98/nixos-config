/*
 * DNS is managed using a hidden master running on my Raspberry Pi 2, which
 * transfers to Afraid FreeDNS (https://freedns.afraid.org/) and PUCK
 * (https://puck.nether.net/). BIND also serves as a caching recursive resolver
 * for my internal network. I use a custom Nix configuration format that allows
 * me to selectively override certain records to be served to the internal
 * network, to implement split horizon DNS without duplicating information.
 */
{ config, lib, pkgs, ... }: with lib; let
  net = config.lib.net;

  zoneRecords = records: concatStringsSep "\n" (map (r: "${r.name} ${optionalString (r ? ttl) r.ttl} ${r.class} ${r.type} ${r.data}") records);
  recordAttrs = records: listToAttrs (map (r: nameValuePair "${r.name}:${r.class}:${r.type}" r) records);
  mergeRecords = parent: child: attrValues (recursiveUpdate (recordAttrs parent) (recordAttrs child));

  externalIPv4 = config.local.networking.home.ipv4PublicAddress;
  ipv4Subnet = config.local.networking.home.ipv4Subnet;
  ipv6Prefix = config.local.networking.home.ipv6SlaacPrefix;

  externalRecords = [
    { name = "@"; class = "IN"; type = "SOA";
      data = ''
        ns2.afraid.org. admin.benwolsieffer.com. (
                        51         ; Serial
                      3600         ; Refresh
                       180         ; Retry
                   2419200         ; Expire
                      1800 )       ; Negative Cache TTL
      '';
    }
    { name = "benwolsieffer.com."; class = "IN"; type = "NS"; data = "ns2.afraid.org."; }
    { name = "benwolsieffer.com."; class = "IN"; type = "NS"; data = "puck.nether.net."; }

    { name = "benwolsieffer.com."; class = "IN"; type = "CAA"; data = "0 issue \"letsencrypt.org\""; }

    # Email forwarding
    { name = "@"; class = "IN"; type = "MX"; data = "10  mx1.improvmx.com."; }
    { name = "@"; class = "IN"; type = "MX"; data = "20  mx2.improvmx.com."; }

    # Website
    { name = "@"; class = "IN"; type = "A"; data = "104.198.14.52"; }
    { name = "www"; class = "IN"; type = "CNAME"; data = "ben-website.netlify.com."; }

    { name = "t3counter"; class = "IN"; type = "CNAME"; data = "t3counter.byethost7.com."; }

    # RasPi2
    { name = "raspi2"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "raspi2"; class = "IN"; type = "AAAA"; data = net.cidr.host "::ba27:ebff:fe5e:6b6e" ipv6Prefix; }

    # ODROID-XU4
    { name = "odroid-xu4"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "odroid-xu4"; class = "IN"; type = "AAAA"; data = net.cidr.host "::b416:dcff:fe31:cbeb" ipv6Prefix; }

    # p-3400
    { name = "p-3400"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "p-3400"; class = "IN"; type = "AAAA"; data = net.cidr.host "::468a:5bff:fece:23c6" ipv6Prefix; }

    # HP-Z420
    #{ name = "hp-z420"; class = "IN"; type = "A"; data = "129.170.92.198"; }
    { name = "hp-z420"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "hp-z420"; class = "IN"; type = "AAAA"; data = net.cidr.host "::a2d3:c1ff:fe20:da3f" ipv6Prefix; }
    { name = "hackerhats"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "arch"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "hydra"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "files"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "doorman"; class = "IN"; type = "CNAME"; data = "hp-z420"; }

    # Rock64
    { name = "rock64"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "rock64"; class = "IN"; type = "AAAA"; data = net.cidr.host "::fc07:23ff:fefc:d03e" ipv6Prefix; }

    # RockPro64
    { name = "rockpro64"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "rockpro64"; class = "IN"; type = "AAAA"; data = net.cidr.host "::b05e:efff:fe50:6aff" ipv6Prefix; }

    # KittyCop
    { name = "kittycop"; class = "IN"; type = "A"; data = "129.170.93.241"; }

    # maine-pi
    { name = "maine-pi"; class = "IN"; type = "CNAME"; data = "maine-pi.nsupdate.info."; }
  ];

  internalRecords = [
    { name = "ns"; class = "IN"; type = "A"; data = net.cidr.host 5 ipv4Subnet; }
    { name = "raspi2"; class = "IN"; type = "A"; data = net.cidr.host 2 ipv4Subnet; }
    { name = "odroid-xu4"; class = "IN"; type = "A"; data = net.cidr.host 3 ipv4Subnet; }
    { name = "dell-optiplex-780"; class = "IN"; type = "A"; data = net.cidr.host 4 ipv4Subnet; }
    { name = "p-3400"; class = "IN"; type = "A"; data = net.cidr.host 4 ipv4Subnet; }
    { name = "hp-z420"; class = "IN"; type = "A"; data = net.cidr.host 5 ipv4Subnet; }
    { name = "rock64"; class = "IN"; type = "A"; data = net.cidr.host 6 ipv4Subnet; }
    { name = "rockpro64"; class = "IN"; type = "A"; data = net.cidr.host 7 ipv4Subnet; }

    { name = "influxdb"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "grafana"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "syncthing.hp-z420"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "syncthing.rockpro64"; class = "IN"; type = "CNAME"; data = "rockpro64"; }
  ];
in {

  services.bind = {
    enable = true;

    configFile = pkgs.writeText "named.conf" ''
      include "/etc/bind/rndc.key";
      controls {
        inet 127.0.0.1 allow { localhost; } keys { "rndc-key"; };
      };

      options {
        directory "/var/run/named";
        pid-file "/var/run/named/named.pid";

        recursion no;
        dnssec-validation auto;

        allow-transfer { none; };
        allow-query { none; };
      };

      acl internal {
        localnets;
        ${config.local.networking.home.ipv6Prefix};
      };

      view "internal" {
        match-clients { internal; };
        allow-query { internal; };
        allow-recursion { internal; };
        recursion yes;

        zone "benwolsieffer.com" {
          type master;

          file "${pkgs.writeText "dns-internal-zone" ''
            $TTL    3600
            ${zoneRecords (mergeRecords externalRecords internalRecords)}
          ''}";
        };
      };

      acl secondaries {
        69.65.50.192;
        2001:1850:1:5:800::6b;
        204.42.254.5;
        2001:418:3f4::5;
      };
      masters secondaries {
        69.65.50.192;
        2001:1850:1:5:800::6b;
        204.42.254.5;
        2001:418:3f4::5;
      };

      view "external" {
        match-clients { secondaries; };
        allow-query { secondaries; };

        zone "benwolsieffer.com" {
          type master;
          allow-transfer { secondaries; };
          notify yes;

          file "${pkgs.writeText "dns-external-zone" ''
            $TTL    3600
            ${zoneRecords externalRecords}
          ''}";
        };
      };
    '';
  };

  networking.firewall = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };
}
