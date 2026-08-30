{ config, lib, pkgs, secrets, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home.amneziawg;
in {

  # Interface

  options.local.networking.vpn.home.amneziawg = {
    ipv4Subnet = mkOption {
      type = net.types.cidrv4;
      readOnly = true;
      default = "192.168.119.0/24";
      description = "IPv4 subnet containing peer addresses";
    };

    ipv6Prefix = mkOption {
      type = net.types.cidrv6;
      readOnly = true;
      description = "IPv6 prefix containing peer addresses";
    };

    peers = mkOption {
      description = "AmneziaWG peers that may connect to the server";
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
    local.networking.vpn.home.amneziawg = {
      ipv6Prefix = net.cidr.subnet
        (64 - net.cidr.length config.local.networking.vpn.home.ipv6Prefix) # length
        1 # subnet number
        config.local.networking.vpn.home.ipv6Prefix; # CIDR

      peers = {
        "+Qy2xNBd+gLpF0MRd/l4xT3YWaXOEqTADnp196a4tSU=".index = 0; # Pixel-4a
      };
    };
  };
}
