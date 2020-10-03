{ config, lib, secrets, ... }:

with lib;

let
  cfg = config.local.networking.wireless.thunderbat;
in {
  # Interface

  options.local.networking.wireless.thunderbat = {
    enable = mkEnableOption "batman-adv mesh WiFi network";

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

    systemd.network = {
      enable = true;
      networks."30-thunderbat" = {
        name = cfg.interface;
        networkConfig.LinkLocalAddressing = "yes";
      };
    };

    environment.etc."wpa_supplicant.conf" = mkForce {
      source = secrets.getSystemdSecret "wpa_supplicant" secrets.wpaSupplicant.thunderbat;
    };

    systemd.secrets.wpa_supplicant = {
      files = secrets.mkSecret secrets.wpaSupplicant.thunderbat { };
      units = singleton "wpa_supplicant.service";
    };
  };
}
