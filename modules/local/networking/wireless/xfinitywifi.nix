{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.local.networking.wireless.xfinitywifi;
in {
  # Interface

  options.local.networking.wireless.xfinitywifi = {
    enable = mkEnableOption "xfinitywifi network";

    interfaces = mkOption {
      type = types.listOf types.str;
      description = "Wireless network interfaces";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    networking.wireless = {
      enable = true;
      inherit (cfg) interfaces;
      networks.xfinitywifi = {};
    };

    systemd.network.networks = listToAttrs (map (interface: {
      name = "30-xfinitywifi-${interface}";
      value = {
        matchConfig.SSID = "xfinitywifi";
        networkConfig.DHCP = "ipv4";
      };
    }) cfg.interfaces);
  };
}
