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
    networking.wireless.enable = true;

    systemd.network = {
      enable = true;
      networks."30-home-wifi" = {
        name = cfg.interface;
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };
    };

    environment.secrets = secrets.mkSecret secrets.wpaSupplicant.homeNetwork {
      target = "wpa_supplicant.conf";
    };
  };
}
