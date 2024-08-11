{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home.wireGuard;
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
  };

  # Implementation

  config = mkMerge [
    {
      local.networking.vpn.home.wireGuard.server = {
        ipv4Address = net.cidr.host 1 cfg.ipv4Subnet;
        ipv6Address = net.cidr.host 1 cfg.ipv6Prefix;
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
            PrivateKeyFile = secrets.getSystemdSecret "vpn-home-wireguard-server" cfg.server.privateKeySecret;
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
            "${cfg.server.ipv4Address}/${toString (net.cidr.length cfg.ipv4Subnet)}"
            "${cfg.server.ipv6Address}/${toString (net.cidr.length cfg.ipv6Prefix)}"
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
        };

        # Enables forwarding globally. Linux has no per-interface setting; you
        # are supposed to use the firewall.
        config.networkConfig.IPv6Forwarding = true;
      };

      local.networking.home.interfaces.${cfg.server.uplinkInterface} = {
        ipv6DelegatedPrefix = cfg.ipv6Prefix;
        ipv4Forwarding = true;
      };

      environment.systemPackages = [ pkgs.wireguard-tools ];

      networking.firewall.allowedUDPPorts = [ cfg.server.port ];

      systemd.secrets.vpn-home-wireguard-server = {
        files = secrets.mkSecret cfg.server.privateKeySecret { user = "systemd-network"; };
        units = [ "systemd-networkd.service" ];
      };
    })
  ];
}
