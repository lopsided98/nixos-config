{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.wireless.apartment;
in {
  # Interface

  options.local.networking.wireless.apartment = {
    enable = mkEnableOption "apartment WiFi network";

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
      networks.Illuin.pskRaw = "ext:APARTMENT_PSK";
    };
    local.networking.wireless.passwordFiles =
      singleton (secrets.getSystemdSecret "wpa_supplicant-apartment" secrets.wpaSupplicant.apartment);

    systemd.network.networks."30-apartment" = mkMerge [
      ({
        name = concatStringsSep " " cfg.interfaces;
        matchConfig.SSID = "Illuin";
        DHCP = "ipv4";
        networkConfig.MulticastDNS = "yes";
      })
      cfg.networkConfig
    ];

    networking.firewall.interfaces = listToAttrs (map (interface: {
      name = interface;
      value = { allowedUDPPorts = [ 5353 /* mDNS */ ]; };
    }) cfg.interfaces);

    systemd.secrets.wpa_supplicant-apartment = {
      files = secrets.mkSecret secrets.wpaSupplicant.apartment { };
      units = map (interface: "wpa_supplicant-${interface}.service") cfg.interfaces;
    };
  };
}
