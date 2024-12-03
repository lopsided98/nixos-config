{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.home;

  interfaceOptions = types.submodule ({ ... }: {
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

      ipv4Forwarding = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to allow IPv4 forwarding on this interface. Linux has no
          per-interface IPv6 forwarding setting.
        '';
      };

      initrd = mkEnableOption "network in initrd";
    };
  });
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
      type = types.attrsOf interfaceOptions;
    };

    initrdInterfaces = mkOption {
      description = "Network interfaces to configure in the initrd";
      default = {};
      type = types.attrsOf interfaceOptions;
    };
  };

  # Implementation

  config = let
    interfaceAttr = interface: interfaceCfg: {
      name = "30-home-${interface}";
      value = mkMerge [
        {
          name = interface;
          inherit (cfg) dns;
          networkConfig = {
            MulticastDNS = "yes";
            # Despite the name, net.ipv6.conf.<interface>.forwarding doesn't
            # control forwarding at all. Instead, it controls the IsRouter flag
            # in neighbor advertisments, whether router advertisments are
            # accepted and whether router solicitations are sent. In practice
            # this probably doesn't matter since systemd-networkd is handling
            # all of this rather than the kernel, but explicitly set it to false
            # anyway to maintain the normal behavior even if other interfaces
            # are using forwarding.
            # See: https://tldp.org/HOWTO/Linux+IPv6-HOWTO/ch11s02.html
            IPv6Forwarding = false;
          };
          dhcpV4Config.UseDNS = false;
          dhcpV6Config = {
            # Router gives out address as part of DHCPv6, but we only want
            # delegated prefix.
            UseAddress = false;
            UseDNS = false;
          };
          ipv6AcceptRAConfig.UseDNS = false;

          # p-3400 suspends when not in use, so it can't respond to ARP
          # requests. Add a static ARP table entry to allow other devices to
          # send packets to it and wake it up.
          extraConfig = ''
            [Neighbor]
            Address=${net.cidr.host 4 cfg.ipv4Subnet}
            LinkLayerAddress=44:8a:5b:ce:23:c6

            [Neighbor]
            Address=${net.cidr.host "::468a:5bff:fece:23c6" cfg.ipv6SlaacPrefix}
            LinkLayerAddress=44:8a:5b:ce:23:c6
          '';
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
        (mkIf (interfaceCfg.ipv4Forwarding) {
          networkConfig.IPv4Forwarding = true;
        })
      ];
    };
  in mkMerge [
    {
      local.networking.home = {
        ipv4PublicAddress = "73.123.249.28";
        ipv4Subnet = "192.168.1.0/24";
        ipv6Prefix = "2601:18c:8002:3d40::/60";
        ipv6SlaacPrefix = net.cidr.subnet (64 - net.cidr.length cfg.ipv6Prefix) 0 cfg.ipv6Prefix;
        dns = [
          (net.cidr.host 2 cfg.ipv4Subnet)
          (net.cidr.host "::ba27:ebff:fe5e:6b6e" cfg.ipv6SlaacPrefix)
        ];

        initrdInterfaces = filterAttrs (_: interfaceCfg: interfaceCfg.initrd) cfg.interfaces;
      };

      assertions = mapAttrsToList (interface: interfaceCfg: {
        assertion = interfaceCfg.ipv6DelegatedPrefix != null -> net.cidr.child interfaceCfg.ipv6DelegatedPrefix cfg.ipv6Prefix;
        message = "Delegated prefix must be a child of the router prefix";
      }) cfg.interfaces;

      systemd.network.networks = mapAttrs' interfaceAttr cfg.interfaces;
      boot.initrd.systemd.network.networks = mapAttrs' interfaceAttr cfg.initrdInterfaces;

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
