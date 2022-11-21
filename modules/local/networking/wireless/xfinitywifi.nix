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

    ignoreBSSIDs = mkOption {
      type = types.listOf types.str;
      description = "BSSIDs that are known to be broken";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    # Some access points are just broken; they fail to respond to DHCP requests.
    local.networking.wireless.xfinitywifi.ignoreBSSIDs = [
      "AA:70:5D:3E:3D:C5"
    ];

    # networking.supplicant is kind of crappy and unmaintained, but it allows
    # separate config files for each interface
    networking.supplicant.${concatStringsSep " " cfg.interfaces} = {
      # Config file must be specified
      configFile.path = mkDefault pkgs.emptyFile;
      extraConf = ''
        network={
          ssid="xfinitywifi"
          key_mgmt=NONE
          bssid_ignore=${concatStringsSep " " cfg.ignoreBSSIDs}
        }
      '';
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
