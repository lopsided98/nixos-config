{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home.wireGuard;

  privateKeyFile = secrets.getSystemdSecret "vpn-home-wireguard-server" cfg.server.privateKeySecret;

  wireguardFwMark = 52998;
  amneziawgFwMark = 52999;
  wireguardTable = 52998;
  amneziawgTable = 52999;
in {

  # Interface

  options.local.networking.vpn.home.wireGuard.server = {
    enable = mkEnableOption "home network WireGuard server";

    interface = mkOption {
      type = types.str;
      description = "VPN network interface name";
      default = "wg0";
    };

    uplinkInterface = mkOption {
      type = types.str;
      description = "Network interface that delegates the IPv6 prefix";
    };

    port = mkOption {
      type = types.int;
      description = "UDP port to listen on";
      default = 4296;
      readOnly = true;
    };

    ipv4Address = mkOption {
      type = net.types.ipv4;
      description = "IPv4 address assigned to WireGuard interface";
      readOnly = true;
    };

    ipv6Address = mkOption {
      type = net.types.ipv6;
      description = "IPv6 address assigned to WireGuard interface";
      readOnly = true;
    };

    privateKeySecret = mkOption {
      type = types.str;
      description = "Server private key secret";
    };

    amneziawg = {
      interface = mkOption {
        type = types.str;
        description = "AmneziaWG network interface name";
        default = "awg0";
      };

      port = mkOption {
        type = types.int;
        description = "UDP port to listen on";
        default = 4297;
        readOnly = true;
      };

      ipv4Address = mkOption {
        type = net.types.ipv4;
        description = "IPv4 address assigned to AmneziaWG interface";
        readOnly = true;
      };

      ipv6Address = mkOption {
        type = net.types.ipv6;
        description = "IPv6 address assigned to AmneziaWG interface";
        readOnly = true;
      };
    };
  };

  # Implementation

  config = mkMerge [
    {
      local.networking.vpn.home.wireGuard.server = {
        ipv4Address = net.cidr.host 1 cfg.ipv4Subnet;
        ipv6Address = net.cidr.host 1 cfg.ipv6Prefix;
        amneziawg = {
          ipv4Address = net.cidr.host 254 cfg.ipv4Subnet;
          ipv6Address = net.cidr.host 254 cfg.ipv6Prefix;
        };
      };
    }
    (mkIf cfg.server.enable {
      systemd.network = {
        netdevs."30-vpn-home-wireguard-server" = {
          netdevConfig = {
            Name = cfg.server.interface;
            Kind = "wireguard";
            MTUBytes = "1392";
          };

          wireguardConfig = {
            ListenPort = toString cfg.server.port;
            PrivateKeyFile = privateKeyFile;
          };

          wireguardPeers = mapAttrsToList (publicKey: peerCfg: {
            AllowedIPs = [
              peerCfg.ipv4Address
              peerCfg.ipv6Address
            ];
            PublicKey = publicKey;
          }) cfg.peers;
        };

        networks."30-vpn-home-wireguard-server" = {
          name = cfg.server.interface;
          address = [
            # No subnet to avoid the default subnet route in the main table. We
            # add it manually to a different table below.
            "${cfg.server.ipv4Address}/32"
            "${cfg.server.ipv6Address}/128"
          ];
          networkConfig = {
            IPv6AcceptRA = false;
            DHCPPrefixDelegation = true;
            IPv4Forwarding = true;
            # Doesn't actually control forwarding and probably doesn't matter if
            # we set it, but it doesn't hurt.
            # See: https://tldp.org/HOWTO/Linux+IPv6-HOWTO/ch11s02.html
            IPv6Forwarding = true;
          };
          dhcpPrefixDelegationConfig = {
            SubnetId = 0;
            Assign = false;
          };
          routes = [
            {
              Destination = "${cfg.ipv4Subnet}";
              Scope = "link";
              Table = wireguardTable;
            }
            {
              Destination = "${cfg.ipv6Prefix}";
              Scope = "link";
              Table = wireguardTable;
            }
          ];
          routingPolicyRules = [
            {
              Table = wireguardTable;
              FirewallMark = wireguardFwMark;
              Family = "both";
            }
            {
              Table = amneziawgTable;
              FirewallMark = amneziawgFwMark;
              Family = "both";
            }
          ];
        };

        # Enables forwarding globally. Linux has no per-interface setting; you
        # are supposed to use the firewall.
        config.networkConfig.IPv6Forwarding = true;
      };

      networking.wg-quick.interfaces.${cfg.server.amneziawg.interface} = {
        type = "amneziawg";
        listenPort = cfg.server.amneziawg.port;
        address = [
          "${cfg.server.amneziawg.ipv4Address}/32"
          "${cfg.server.amneziawg.ipv6Address}/128"
        ];
        privateKeyFile = secrets.getSystemdSecret "vpn-home-amneziawg-server" cfg.server.privateKeySecret;
        peers = mapAttrsToList (publicKey: peerCfg: {
          allowedIPs = [
            peerCfg.ipv4Address
            peerCfg.ipv6Address
          ];
          publicKey = publicKey;
        }) cfg.peers;
        table = builtins.toString amneziawgTable;
      };

      networking.nftables = {
        enable = true;
        tables.vpn-home-wireguard-routing = let
          ingress-tracking-rules = fwMark: ''
            # Add the correct mapping
            update @ipv4_addr_mark { ip saddr : ${builtins.toString fwMark} }
            update @ipv6_addr_mark { ip6 saddr : ${builtins.toString fwMark} }

            # Set mark on incoming packets to allow them to pass rpfilter check
            meta mark set ${builtins.toString fwMark}
          '';
        in {
            family = "inet";
            content = ''
              map ipv4_addr_mark {
                  type ipv4_addr : mark
                  flags dynamic
                  size 256
              }

              map ipv6_addr_mark {
                  type ipv6_addr : mark
                  flags dynamic
                  size 256
              }

              chain wireguard_ingress_tracking {
                  ${ingress-tracking-rules wireguardFwMark}
              }

              chain amneziawg_ingress_tracking {
                  ${ingress-tracking-rules amneziawgFwMark}
              }

              chain ingress_tracking {
                  type filter hook prerouting priority mangle; policy accept;

                  iifname "${cfg.server.interface}" jump wireguard_ingress_tracking
                  iifname "${cfg.server.amneziawg.interface}" jump amneziawg_ingress_tracking
              }

              chain egress_prerouting_mark {
                  type filter hook prerouting priority mangle; policy accept;

                  # Set mark on forwarded packets
                  ip daddr ${cfg.ipv4Subnet} meta mark set ip daddr map @ipv4_addr_mark
                  ip6 daddr ${cfg.ipv6Prefix} meta mark set ip6 daddr map @ipv6_addr_mark
              }

              chain egress_output_mark {
                  type route hook output priority filter; policy accept;

                  # Set mark on locally generated packets
                  ip daddr ${cfg.ipv4Subnet} meta mark set ip daddr map @ipv4_addr_mark
                  ip6 daddr ${cfg.ipv6Prefix} meta mark set ip6 daddr map @ipv6_addr_mark
              }
            '';
          };
      };

      local.networking.home.interfaces.${cfg.server.uplinkInterface} = {
        ipv6DelegatedPrefix = cfg.ipv6Prefix;
        ipv4Forwarding = true;
      };

      environment.systemPackages = [ pkgs.wireguard-tools ];

      networking.firewall = {
        logReversePathDrops = true;
        allowedUDPPorts = [ cfg.server.port cfg.server.amneziawg.port ];
      };

      systemd.secrets = {
        vpn-home-wireguard-server = {
          files = secrets.mkSecret cfg.server.privateKeySecret { user = "systemd-network"; };
          units = [ "systemd-networkd.service" ];
        };
        vpn-home-amneziawg-server = {
          files = secrets.mkSecret cfg.server.privateKeySecret { };
          units = [ "wg-quick-${cfg.server.amneziawg.interface}.service" ];
        };
      };
    })
  ];
}
