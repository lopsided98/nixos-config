{ config, lib, ... }:

with lib;

let
  net = config.lib.net;
  cfg = config.local.networking.vpn.home;
in {

  # Interface

  options.local.networking.vpn.home = {
    ipv6Prefix = mkOption {
      type = net.types.cidrv6;
      readOnly = true;
      description = "IPv6 prefix to allocate VPN subnets";
    };
  };

  # Implementation

  config = {
    local.networking.vpn.home.ipv6Prefix = net.cidr.subnet
      3 # length
      1 # subnet number
      config.local.networking.home.ipv6Prefix; # CIDR
  };
}
