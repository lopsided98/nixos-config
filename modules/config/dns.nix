/*
 * DNS is managed using a hidden master running on my Raspberry Pi 2, which
 * transfers to Afraid FreeDNS (https://freedns.afraid.org/) and PUCK
 * (https://puck.nether.net/). BIND also serves as a caching recursive resolver
 * for my internal network. I use a custom Nix configuration format that allows
 * me to selectively override certain records to be served to the internal
 * network, to implement split horizon DNS without duplicating information.
 */
{ config, lib, pkgs, ... }: with lib; let
  zoneRecords = records: concatStringsSep "\n" (map (r: "${r.name} ${optionalString (r ? ttl) r.ttl} ${r.class} ${r.type} ${r.data}") records);
  recordAttrs = records: listToAttrs (map (r: nameValuePair "${r.name}:${r.class}:${r.type}" r) records);
  mergeRecords = parent: child: attrValues (recursiveUpdate (recordAttrs parent) (recordAttrs child));

  externalIPv4 = "73.149.219.1";
  externalRecords = [
    { name = "@"; class = "IN"; type = "SOA";
      data = ''
        ns2.afraid.org. admin.benwolsieffer.com. (
                        35         ; Serial
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

    { name = "t3counter"; class = "IN"; type = "CNAME"; data = "t3counter.byethost31.com."; }

    # RasPi2
    { name = "raspi2"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "raspi2"; class = "IN"; type = "AAAA"; data = "2601:18a:0:7723:ba27:ebff:fe5e:6b6e"; }

    # ODROID-XU4
    { name = "odroid-xu4"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "odroid-xu4"; class = "IN"; type = "AAAA"; data = "2601:18a:0:7723:b416:dcff:fe31:cbeb"; }

    # Dell-Optiplex-780
    { name = "dell-optiplex-780"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "dell-optiplex-780"; class = "IN"; type = "AAAA"; data = "2601:18a:0:7723:225:64ff:febd:bdbc"; }

    # HP-Z420
    { name = "hp-z420"; class = "IN"; type = "A"; data = "129.170.92.145"; }
    #{ name = "hp-z420"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "hp-z420"; class = "IN"; type = "AAAA"; data = "2601:18a:0:7723:a2d3:c1ff:fe20:da3f"; }
    { name = "hackerhats"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "arch"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "hydra"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "doorman"; class = "IN"; type = "CNAME"; data = "hp-z420"; }

    # Rock64
    { name = "rock64"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "rock64"; class = "IN"; type = "AAAA"; data = "2601:18a:0:7723:84e0:c0ff:feea:faa9"; }

    # RockPro64
    { name = "rockpro64"; class = "IN"; type = "A"; data = externalIPv4; }
    { name = "rockpro64"; class = "IN"; type = "AAAA"; data = "2601:18a:0:7723:b05e:efff:fe50:6aff"; }

    # KittyCop
    { name = "kittycop"; class = "IN"; type = "A"; data = "129.170.93.241"; }

    # maine-pi
    { name = "maine-pi"; class = "IN"; type = "CNAME"; data = "maine-pi.awsmppl.com."; }
  ];

  internalRecords = [
    { name = "ns"; class = "IN"; type = "A"; data = "192.168.1.5"; }
    { name = "raspi2"; class = "IN"; type = "A"; data = "192.168.1.2"; }
    { name = "odroid-xu4"; class = "IN"; type = "A"; data = "192.168.1.3"; }
    { name = "dell-optiplex-780"; class = "IN"; type = "A"; data = "192.168.1.4"; }
    { name = "hp-z420"; class = "IN"; type = "A"; data = "192.168.1.5"; }
    { name = "rock64"; class = "IN"; type = "A"; data = "192.168.1.6"; }
    { name = "rockpro64"; class = "IN"; type = "A"; data = "192.168.1.7"; }

    { name = "influxdb"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "grafana"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "syncthing.hp-z420"; class = "IN"; type = "CNAME"; data = "hp-z420"; }
    { name = "syncthing.rock64"; class = "IN"; type = "CNAME"; data = "rock64"; }
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

      acl internal { localnets; };

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

      acl slaves {
        69.65.50.192;
        2001:1850:1:5:800::6b;
        204.42.254.5;
        2001:418:3f4::5;
      };
      masters slaves {
        69.65.50.192;
        2001:1850:1:5:800::6b;
        204.42.254.5;
        2001:418:3f4::5;
      };

      view "external" {
        match-clients { slaves; };
        allow-query { slaves; };

        zone "benwolsieffer.com" {
          type master;
          allow-transfer { slaves; };
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
