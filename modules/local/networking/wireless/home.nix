{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.wireless.home;
in {
  # Interface

  options.local.networking.wireless.home = {
    enable = mkEnableOption "home WiFi network";

    interface = mkOption {
      type = types.str;
      description = "Wireless network interface";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    networking.wireless = {
      enable = true;
      interfaces = [ cfg.interface ];
    };

    environment.etc."wpa_supplicant.conf" = mkForce {
      source = secrets.getSystemdSecret "wpa_supplicant" secrets.wpaSupplicant.homeNetwork;
    };

    local.networking.home = {
      enable = true;
      interfaces = [ cfg.interface ];
    };

    systemd.secrets.wpa_supplicant = {
      files = secrets.mkSecret secrets.wpaSupplicant.homeNetwork { };
      units = singleton "wpa_supplicant.service";
    };
  };
}
