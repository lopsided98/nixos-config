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

    port = mkOption {
      type = types.int;
      description = "UDP port to listen on";
      default = 4296;
    };

    ipv4Address = mkOption {
      type = net.types.ipv4;
      readOnly = true;
      description = "IPv4 address assigned to WireGuard interface";
    };

    ipv6Address = mkOption {
      type = net.types.ipv6;
      readOnly = true;
      description = "IPv6 address assigned to WireGuard interface";
    };

    privateKeySecret = mkOption {
      type = types.str;
      description = "Server private key secret";
    };
  };

  # Implementation

  config = mkIf cfg.server.enable {
    local.networking.vpn.home.wireGuard.server = {
      ipv4Address = net.cidr.host 1 cfg.ipv4Subnet;
      ipv6Address = net.cidr.host 1 cfg.ipv6Prefix;
    };

    systemd.network = {
      netdevs."30-vpn-home-wireguard-server" = {
        netdevConfig = {
          Name = cfg.server.interface;
          Kind = "wireguard";
          MTUBytes = "1400";
        };

        wireguardConfig = {
          ListenPort = toString cfg.server.port;
          PrivateKeyFile = secrets.getSystemdSecret "vpn-home-wireguard-server" cfg.server.privateKeySecret;
        };

        wireguardPeers = mapAttrsToList (publicKey: peerCfg: {
          wireguardPeerConfig = {
            AllowedIPs = [
              peerCfg.ipv4Address
              peerCfg.ipv6Address
            ];
            PublicKey = publicKey;
          };
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
          DHCPv6PrefixDelegation = true;
          IPForward = true;
        };
        dhcpV6PrefixDelegationConfig = {
          SubnetId = 0;
          Assign = false;
        };
      };
    };

    local.networking.home.ipv6DelegatedPrefix = cfg.ipv6Prefix;

    environment.systemPackages = [ pkgs.wireguard-tools ];

    networking.firewall.allowedUDPPorts = [ cfg.server.port ];

    systemd.secrets.vpn-home-wireguard-server = {
      files = mkMerge [
        (secrets.mkSecret cfg.server.privateKeySecret { user = "systemd-network"; })
      ];
      units = [ "systemd-networkd.service" ];
    };
  };
}
