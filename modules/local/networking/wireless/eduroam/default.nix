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
      networks.eduroam = {
        authProtocols = [ "WPA-EAP" ];
        auth = ''
          pairwise=CCMP
          group=CCMP TKIP
          eap=PEAP
          ca_cert="${./eduroam_ca.pem}"
          identity="f002w9k@dartmouth.edu"
          altsubject_match="DNS:radius.dartmouth.edu"
          phase2="auth=MSCHAPV2"
          password=ext:EDUROAM_PASSWORD
          anonymous_identity="anonymous@dartmouth.edu"
        '';
      };
    };
    local.networking.wireless.passwordFiles =
      singleton (secrets.getSystemdSecret "wpa_supplicant-eduroam" secrets.wpaSupplicant.eduroam);

    systemd.network.networks."30-eduroam" = mkMerge [
      {
        name = concatStringsSep " " cfg.interfaces;
        matchConfig.SSID = "eduroam";
        DHCP = "ipv4";
        networkConfig = {
          Domains = [ "~dartmouth.edu" ];
          DNSDefaultRoute = true;
        };
      }
      cfg.networkConfig
    ];

    systemd.secrets.wpa_supplicant-eduroam = {
      files = secrets.mkSecret secrets.wpaSupplicant.eduroam { };
      units = map (interface: "wpa_supplicant-${interface}.service") cfg.interfaces;
    };
  };
}
