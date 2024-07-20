{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home.wireGuard;
  peer = cfg.peers.${cfg.client.publicKey};

  serverHostName = "atomic-pi.benwolsieffer.com";
  serverPublicKey = "+6YE+L1kyBmvbQ4GKpw20g2vQv/58QujDHCCCIqzH14=";
in {

  # Interface

  options.local.networking.vpn.home.wireGuard.client = {
    enable = mkEnableOption "home network WireGuard client";

    interface = mkOption {
      type = types.str;
      description = "VPN network interface name";
      default = "wg0";
    };

    outgoingInterfaces = mkOption {
      type = types.listOf types.str;
      description = "Interfaces to use to connect to server";
    };

    publicKey = mkOption {
      type = types.str;
      description = ''
        Client public key. Must be in the configured list of peers.
      '';
    };

    privateKeySecret = mkOption {
      type = types.str;
      description = "Client private key secret";
    };

    persistentKeepalive = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable persistent keepalives";
    };

    firewallMark = mkOption {
      type = types.int;
      default = 51820;
      description = "Firewall mark to apply to outgoing WireGuard packets";
    };

    networkConfig = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Extra systemd-networkd configuration options for this network
      '';
    };
  };

  # Implementation

  config = mkIf cfg.client.enable {
    systemd.network = {
      config.routeTables.vpn-home-wireguard-client = 51950;

      netdevs."30-vpn-home-wireguard-client" = {
        netdevConfig = {
          Name = cfg.client.interface;
          Kind = "wireguard";
          MTUBytes = "1392";
        };

        wireguardConfig = {
          PrivateKeyFile = secrets.getSystemdSecret "vpn-home-wireguard-client" cfg.client.privateKeySecret;
          FirewallMark = cfg.client.firewallMark;
        };

        wireguardPeers = [ {
          AllowedIPs = [ "0.0.0.0/0" "::/0" ];
          PublicKey = serverPublicKey;
          PersistentKeepalive = mkIf cfg.client.persistentKeepalive 25;
        } ];
      };

      networks."30-vpn-home-wireguard-client" = mkMerge [
        {
          name = cfg.client.interface;
          address = [
            "${peer.ipv4Address}/${toString (net.cidr.length cfg.ipv4Subnet)}"
            "${peer.ipv6Address}/${toString (net.cidr.length cfg.ipv6Prefix)}"
          ];
          inherit (config.local.networking.home) dns;
          networkConfig = {
            Domains = [ "~benwolsieffer.com" ];
            DNSDefaultRoute = true;
          };
          routes = [
            # FIXME: default gateway breaks things
            /*{
              Gateway = cfg.server.ipv4Address;
              Table = "vpn-home-wireguard-client";
            }
            {
              Gateway = cfg.server.ipv6Address;
              Table = "vpn-home-wireguard-client";
            }*/
            {
              Destination = config.local.networking.home.ipv4Subnet;
              Gateway = cfg.server.ipv4Address;
              Table = "vpn-home-wireguard-client";
            }
            {
              Destination = config.local.networking.home.ipv6Prefix;
              Gateway = cfg.server.ipv6Address;
              Table = "vpn-home-wireguard-client";
            }
          ];
          routingPolicyRules = [
            {
              Table = "vpn-home-wireguard-client";
              SuppressPrefixLength = 0;
              Family = "both";
              Priority = 31698;
            }
            {
              Table = "vpn-home-wireguard-client";
              InvertRule = true;
              FirewallMark = cfg.client.firewallMark;
              Family = "both";
              Priority = 31699;
            }
          ];
        }
        cfg.client.networkConfig
      ];
    };

    systemd.services.vpn-home-wireguard-client-update = let
      interfaceDevice = "sys-devices-virtual-net-${cfg.client.interface}.device";
    in {
      description = "Update home WireGuard VPN endpoint";
      wantedBy = [ interfaceDevice ];
      bindsTo = [ interfaceDevice ];
      after = [ interfaceDevice ];
      serviceConfig.Type = "oneshot";
      path = with pkgs; [
        coreutils
        gawk
        systemd
        iputils
        wireguard-tools
      ];
      script = ''
        set -eu -o pipefail

        function set_endpoint() {
          wg set ${escapeShellArg cfg.client.interface} \
            peer ${escapeShellArg serverPublicKey} \
            endpoint "$1":${toString cfg.server.port}
        }

        function get_address() {
          local address
          if ! address="$(resolvectl query --legend=false -i "$1" -"$2" ${escapeShellArg serverHostName} | head -n1 | awk '{print $2}')"; then
            return 1
          fi
          if ping -qn -I "$1" -m ${toString cfg.client.firewallMark} -c1 -W10 "$address" 1>&2; then
            echo "$address"
            return 0
          else
            return 1
          fi
        }

        for interface in ${lib.escapeShellArgs cfg.client.outgoingInterfaces}; do
          if address="$(get_address "$interface" 4)"; then
            set_endpoint "$address"
            exit 0
          fi
        done

        # Fallback to hardcoded IPv4 address
        set_endpoint ${escapeShellArg config.local.networking.home.ipv4PublicAddress}
        exit 1
      '';
    };

    systemd.timers.vpn-home-wireguard-client-update = {
      description = "Update home WireGuard VPN endpoint";
      partOf = [ "vpn-home-wireguard-client-update.service" ];
      wantedBy = [ "timers.target" ];
      timerConfig.OnUnitActiveSec = "5m";
    };

    environment.systemPackages = [ pkgs.wireguard-tools ];

    systemd.secrets.vpn-home-wireguard-client = {
      files = secrets.mkSecret cfg.client.privateKeySecret { user = "systemd-network"; };
      units = [ "systemd-networkd.service" ];
    };
  };
}
