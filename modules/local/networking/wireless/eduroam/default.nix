{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.wireless.eduroam;
in {
  # Interface

  options.local.networking.wireless.eduroam = {
    enable = mkEnableOption "eduroam WiFi network";

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
      environmentFiles = singleton (secrets.getSystemdSecret "wpa_supplicant-eduroam" secrets.wpaSupplicant.eduroam);
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
        name = concatStringsSep " " cfg.interfaces;
        matchConfig.SSID = "eduroam";
        DHCP = "ipv4";
      };
    };

    systemd.secrets.wpa_supplicant-eduroam = {
      files = secrets.mkSecret secrets.wpaSupplicant.eduroam { };
      units = map (interface: "wpa_supplicant-${interface}.service") cfg.interfaces;
    };
  };
}
