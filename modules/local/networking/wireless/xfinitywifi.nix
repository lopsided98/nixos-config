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

    networkConfig = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Extra systemd-networkd configuration options for this network
      '';
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    networking.wireless = {
      enable = true;
      inherit (cfg) interfaces;
      networks.xfinitywifi = {};
    };

    systemd.network.networks."30-xfinitywifi" = mkMerge [
      ({
        name = concatStringsSep " " cfg.interfaces;
        matchConfig.SSID = "xfinitywifi";
        DHCP = "ipv4";
      })
      cfg.networkConfig
    ];
  };
}
