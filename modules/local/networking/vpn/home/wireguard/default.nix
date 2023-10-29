{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home.wireGuard;
in {

  # Interface

  options.local.networking.vpn.home.wireGuard = {
    ipv4Subnet = mkOption {
      type = net.types.cidrv4;
      readOnly = true;
      default = "192.168.118.0/24";
      description = "IPv4 subnet containing peer addresses";
    };

    ipv6Prefix = mkOption {
      type = net.types.cidrv6;
      readOnly = true;
      description = "IPv6 prefix containing peer addresses";
    };

    peers = mkOption {
      description = "WireGuard peers that may connect to the server";
      default = {};
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options = {
          index = mkOption {
            type = types.int;
            description = "Peer index used to assign IP addresses";
          };

          ipv4Address = mkOption {
            type = types.str;
            readOnly = true;
            description = "Peer IPv4 address";
          };

          ipv6Address = mkOption {
            type = types.str;
            readOnly = true;
            description = "Peer IPv6 address";
          };
        };

        config = {
          ipv4Address = net.cidr.host (config.index + 2) cfg.ipv4Subnet;
          ipv6Address = net.cidr.host (config.index + 2) cfg.ipv6Prefix;
        };
      }));
    };
  };

  # Implementation

  config = {
    local.networking.vpn.home.wireGuard = {
      ipv6Prefix = net.cidr.subnet
        (64 - net.cidr.length config.local.networking.home.ipv6Prefix) # length
        1 # subnet number
        config.local.networking.home.ipv6Prefix; # CIDR

      peers = {
        "sBNbbhUP9l73RYWDeKBS4/P/Ev4PrKK/RbYJP1WYZzI=".index = 0; # Dell-Inspiron-15
        "+Qy2xNBd+gLpF0MRd/l4xT3YWaXOEqTADnp196a4tSU=".index = 1; # Pixel-4a
        "sVgdQpaigfOLO2nvYP7U1XcfzAml8dzZRjAcEmYfTQ0=".index = 2; # maine-pi
      };
    };
  };
}
