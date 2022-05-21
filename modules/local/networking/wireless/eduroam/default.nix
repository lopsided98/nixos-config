{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.wireless.eduroam;
in {
  # Interface

  options.local.networking.wireless.eduroam = {
    enable = mkEnableOption "eduroam WiFi network";

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

    environment.etc = {
      "wpa_supplicant.conf" = mkForce {
        source = secrets.getSystemdSecret "wpa_supplicant" secrets.wpaSupplicant.eduroam;
      };
      "wpa_supplicant/eduroam_ca.pem".source = ./eduroam_ca.pem;
    };

    systemd.network = {
      enable = true;
      networks."30-eduroam" = {
        name = cfg.interface;
        DHCP = "ipv4";
      };
    };

    systemd.secrets.wpa_supplicant = {
      files = secrets.mkSecret secrets.wpaSupplicant.eduroam { };
      units = singleton "wpa_supplicant-${cfg.interface}.service";
    };
  };
}
