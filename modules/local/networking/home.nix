{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.home;
in {
  # Interface

  options.local.networking.home = {
    enable = mkEnableOption "home network";

    interfaces = mkOption {
      type = types.listOf types.str;
      description = "Network interface";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    systemd.network = {
      enable = true;
      networks."30-home" = {
        name = concatStringsSep " " cfg.interfaces;
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };
    };
  };
}
