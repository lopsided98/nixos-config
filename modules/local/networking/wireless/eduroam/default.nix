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
      environmentFile = secrets.getSystemdSecret "wpa_supplicant-eduroam" secrets.wpaSupplicant.eduroam;
      networks.eduroam = {
        authProtocols = [ "WPA-EAP" ];
        auth = ''
          pairwise=CCMP
          group=CCMP TKIP
          eap=PEAP
          ca_cert="${./eduroam_ca.pem}"
          identity="@EDUROAM_NETID@@dartmouth.edu"
          altsubject_match="DNS:radius.dartmouth.edu"
          phase2="auth=MSCHAPV2"
          password="@EDUROAM_PASSWORD@"
          anonymous_identity="anonymous@dartmouth.edu"
        '';
      };
    };

    systemd.network = {
      enable = true;
      networks."30-eduroam" = {
        name = cfg.interface;
        DHCP = "ipv4";
      };
    };

    systemd.secrets.wpa_supplicant-eduroam = {
      files = secrets.mkSecret secrets.wpaSupplicant.eduroam { };
      units = singleton "wpa_supplicant-${cfg.interface}.service";
    };
  };
}
