{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.home;

  dns = [ "192.168.1.2" "2601:18a:0:1b5c:ba27:ebff:fe5e:6b6e" ];
in {
  # Interface

  options.local.networking.home = {
    enable = mkEnableOption "home network";

    interfaces = mkOption {
      type = types.listOf types.str;
      description = "Network interfaces";
    };

    ipv4Address = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Static IPv4 address to set. If not set, DHCP is used. Only really makes
        sense with a single interface for now.
      '';
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    systemd.network = {
      enable = true;
      networks."30-home" = mkMerge [
        {
          name = concatStringsSep " " cfg.interfaces;
          inherit dns;
          dhcpV4Config.UseDNS = false;
          dhcpV6Config.UseDNS = false;
          extraConfig = ''
            [IPv6AcceptRA]
            UseDNS=no
          '';
        }
        (if cfg.ipv4Address == null then {
          DHCP = "ipv4";
        } else {
          address = [ cfg.ipv4Address ];
          gateway = [ "192.168.1.1" ];
        })
      ];
    };

    # Fallback DNS config for systems that don't use resolved
    environment.etc."resolv.conf".text = mkIf (!config.services.resolved.enable)
      (concatMapStringsSep "\n" (s: "nameserver ${s}") dns);
  };
}
