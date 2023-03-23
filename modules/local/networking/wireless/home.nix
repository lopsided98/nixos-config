{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.wireless.home;
in {
  # Interface

  options.local.networking.wireless.home = {
    enable = mkEnableOption "home WiFi network";

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
  };

  # Implementation

  config = mkIf cfg.enable {
    networking.wireless = {
      enable = true;
      inherit (cfg) interfaces;
      networks = {
        Thunderbolt = {
          authProtocols = [ "WPA-PSK" "SAE" ] ++ lib.optional cfg.enableWpa2Sha256 "WPA-PSK-SHA256";
          pskRaw = "ext:HOME_PSK";
        };
        Thunderbolt_5GHz = {
          authProtocols = [ "WPA-PSK" "SAE" ] ++ lib.optional cfg.enableWpa2Sha256 "WPA-PSK-SHA256";
          pskRaw = "ext:HOME_PSK";
        };
      };
    };
    local.networking.wireless.passwordFiles =
      singleton (secrets.getSystemdSecret "wpa_supplicant-home" secrets.wpaSupplicant.home);

    local.networking.home.interfaces = listToAttrs (map (i: nameValuePair i {}) cfg.interfaces);

    systemd.network.networks = listToAttrs (map (interface: {
      name = "30-home-${interface}";
      value = { matchConfig.SSID = "Thunderbolt Thunderbolt_5GHz"; };
    }) cfg.interfaces);

    systemd.secrets.wpa_supplicant-home = {
      files = secrets.mkSecret secrets.wpaSupplicant.home { };
      units = map (interface: "wpa_supplicant-${interface}.service") cfg.interfaces;
    };
  };
}
