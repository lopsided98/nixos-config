{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.wireless.apartment;
in {
  # Interface

  options.local.networking.wireless.apartment = {
    enable = mkEnableOption "apartment network";

    interfaces = mkOption {
      type = types.listOf types.str;
      description = "Wireless network interfaces";
    };

    enableWpa2Sha256 = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable WPA2-SHA256 support. This causes connections to fail on some
        devices (Raspberry Pi Zero W), while others (Raspberry Pi 4) won't
        connect without it.
      '';
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
      networks."Doctor Who" = {
        authProtocols = [ "WPA-PSK" "SAE" ] ++ lib.optional cfg.enableWpa2Sha256 "WPA-PSK-SHA256";
        pskRaw = "ext:APARTMENT_PSK";
      };
    };
    local.networking.wireless.passwordFiles =
      singleton (secrets.getSystemdSecret "wpa_supplicant-apartment" secrets.wpaSupplicant.apartment);

    systemd.network.networks."30-apartment" = mkMerge [
      ({
        name = concatStringsSep " " cfg.interfaces;
        # Need to manually insert quotes around SSIDs with spaces
        matchConfig.SSID = "\"Doctor Who\"";
        DHCP = "ipv4";
        networkConfig.MulticastDNS = "yes";
      })
      cfg.networkConfig
    ];

    networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
      allowedUDPPorts = [ 5353 /* mDNS */ ];
    });

    systemd.secrets.wpa_supplicant-apartment = {
      files = secrets.mkSecret secrets.wpaSupplicant.apartment {
        user = "wpa_supplicant";
        group = "wpa_supplicant";
      };
      units = map (interface: "wpa_supplicant-${interface}.service") cfg.interfaces;
    };
  };
}
