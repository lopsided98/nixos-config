{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.home;

  dns = [
    (net.cidr.host 2 cfg.ipv4Subnet)
    (net.cidr.host "::ba27:ebff:fe5e:6b6e" cfg.ipv6SlaacPrefix)
  ];
in {
  # Interface

  options.local.networking.home = {
    enable = mkEnableOption "home network";

    ipv4PublicAddress = mkOption {
      type = net.types.ipv4;
      default = null;
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

    interfaces = mkOption {
      type = types.listOf types.str;
      description = "Network interfaces";
    };

    ipv4Address = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Static IPv4 address to set. If not set, DHCP is used. If more than one
        interface is configured, this address will only be used on the first
        and the rest will be configured with DHCP.
      '';
    };

    ipv6DelegatedPrefix = mkOption {
      type = types.nullOr net.types.cidrv6;
      default = null;
      description = "IPv6 prefix delegation to request using DHCPv6";
    };
  };

  # Implementation

  config = mkMerge [
    {
      local.networking.home = {
        ipv4Subnet = "192.168.1.0/24";
        ipv6Prefix = "2601:18c:8380:74b0::/60";
        ipv6SlaacPrefix = net.cidr.subnet (64 - net.cidr.length cfg.ipv6Prefix) 0 cfg.ipv6Prefix;
      };
    }
    (mkIf cfg.enable {
      assertions = singleton {
        assertion = net.cidr.child cfg.ipv6DelegatedPrefix cfg.ipv6Prefix;
        message = "Delegated prefix must be a child of the router prefix";
      };

      systemd.network = {
        enable = true;
        networks = listToAttrs (imap0 (i: interface: {
          name = "30-home-${interface}";
          value = mkMerge [
            {
              name = interface;
              inherit dns;
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
            (if cfg.ipv4Address == null || i > 0 then {
              DHCP = if cfg.ipv6DelegatedPrefix == null then "ipv4" else "yes";
            } else {
              DHCP = if cfg.ipv6DelegatedPrefix == null then "no" else "ipv6";
              address = [ cfg.ipv4Address ];
              gateway = [ (net.cidr.host 1 cfg.ipv4Subnet) ];
            })
            (mkIf (cfg.ipv6DelegatedPrefix != null) {
              dhcpV6Config = {
                # Router doesn't set M flag, since we normally want devices to
                # use SLAAC only. Therefore, we have to manually ask for DHCPv6
                # to delegate a prefix.
                WithoutRA = "solicit";
                PrefixDelegationHint = cfg.ipv6DelegatedPrefix;
              };
            })
          ];
        }) cfg.interfaces);
      };

      # Fallback DNS config for systems that don't use resolved
      environment.etc."resolv.conf".text = mkIf (!config.services.resolved.enable)
        (concatMapStringsSep "\n" (s: "nameserver ${s}") dns);
    })
  ];
}
