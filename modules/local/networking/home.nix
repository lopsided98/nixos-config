{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.home;
in {
  # Interface

  options.local.networking.home = {
    enable = mkEnableOption "home network";

    ipv4PublicAddress = mkOption {
      type = net.types.ipv4;
      readOnly = true;
      description = "Public IPv4 address assigned to router";
    };

    ipv4Subnet = mkOption {
      type = net.types.cidrv4;
      readOnly = true;
      description = "Internal IPv4 subnet";
    };

    ipv6Prefix = mkOption {
      type = net.types.cidrv6;
      readOnly = true;
      description = "IPv6 prefix assigned to router";
    };

    ipv6SlaacPrefix = mkOption {
      type = net.types.cidrv6;
      readOnly = true;
      description = "IPv6 prefix assigned to router";
    };

    dns = mkOption {
      type = types.listOf net.types.ip;
      readOnly = true;
      description = "DNS servers";
    };

    interfaces = mkOption {
      description = "Network interfaces to configure";
      default = {};
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options = {
          ipv4Address = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Static IPv4 address to set. If not set, DHCP is used. If more than one
              interface is configured, this address will only be used on the first
              and the rest will be configured with DHCP.
            '';
          };

          ipv6Address = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Static IPv6 address to set. If not set, SLAAC is used. If more than one
              interface is configured, this address will only be used on the first
              and the rest will be configured with SLAAC.
            '';
          };

          ipv6DelegatedPrefix = mkOption {
            type = types.nullOr net.types.cidrv6;
            default = null;
            description = "IPv6 prefix delegation to request using DHCPv6";
          };
        };
      }));
    };
  };

  # Implementation

  config = mkMerge [
    {
      local.networking.home = {
        ipv4PublicAddress = "73.149.35.171";
        ipv4Subnet = "192.168.1.0/24";
        ipv6Prefix = "2601:18c:8380:74b0::/60";
        ipv6SlaacPrefix = net.cidr.subnet (64 - net.cidr.length cfg.ipv6Prefix) 0 cfg.ipv6Prefix;
        dns = [
          (net.cidr.host 2 cfg.ipv4Subnet)
          (net.cidr.host "::ba27:ebff:fe5e:6b6e" cfg.ipv6SlaacPrefix)
        ];
      };

      assertions = mapAttrsToList (interface: interfaceCfg: {
        assertion = interfaceCfg.ipv6DelegatedPrefix != null -> net.cidr.child interfaceCfg.ipv6DelegatedPrefix cfg.ipv6Prefix;
        message = "Delegated prefix must be a child of the router prefix";
      }) cfg.interfaces;

      systemd.network.networks = mapAttrs' (interface: interfaceCfg: {
        name = "30-home-${interface}";
        value = mkMerge [
          {
            name = interface;
            inherit (cfg) dns;
            networkConfig.MulticastDNS = "yes";
            dhcpV4Config.UseDNS = false;
            dhcpV6Config = {
              # Router gives out address as part of DHCPv6, but we only want
              # delegated prefix.
              UseAddress = false;
              UseDNS = false;
            };
            ipv6AcceptRAConfig.UseDNS = false;
          }
          (if interfaceCfg.ipv4Address == null then {
            DHCP = if interfaceCfg.ipv6DelegatedPrefix == null then "ipv4" else "yes";
          } else {
            DHCP = if interfaceCfg.ipv6DelegatedPrefix == null then "no" else "ipv6";
            address = [ interfaceCfg.ipv4Address ];
            gateway = [ (net.cidr.host 1 cfg.ipv4Subnet) ];
          })
          (mkIf (interfaceCfg.ipv6Address != null) {
            address = [ interfaceCfg.ipv6Address ];
            networkConfig.IPv6AcceptRA = "no";
          })
          (mkIf (interfaceCfg.ipv6DelegatedPrefix != null) {
            dhcpV6Config = {
              # Router doesn't set M flag, since we normally want devices to
              # use SLAAC only. Therefore, we have to manually ask for DHCPv6
              # to delegate a prefix.
              WithoutRA = "solicit";
              PrefixDelegationHint = interfaceCfg.ipv6DelegatedPrefix;
            };
          })
        ];
      }) cfg.interfaces;

      networking.firewall.interfaces = mapAttrs (_: _: {
        allowedUDPPorts = [ 5353 /* mDNS */ ];
      }) cfg.interfaces;
    }
    (mkIf (cfg.interfaces != {}) {
      # Fallback DNS config for systems that don't use resolved
      environment.etc."resolv.conf".text = mkIf (!config.services.resolved.enable)
        (concatMapStringsSep "\n" (s: "nameserver ${s}") dns);
    })
  ];
}
