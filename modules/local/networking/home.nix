{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.home;

  dns = [ "192.168.1.2" "2601:18c:8380:74b0:ba27:ebff:fe5e:6b6e" ];
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
        Static IPv4 address to set. If not set, DHCP is used. If more than one
        interface is configured, this address will only be used on the first
        and the rest will be configured with DHCP.
      '';
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    systemd.network = {
      enable = true;
      networks = listToAttrs (imap0 (i: interface: {
        name = "30-home-${interface}";
        value = mkMerge [
          {
            name = interface;
            inherit dns;
            networkConfig.MulticastDNS = "yes";
            dhcpV4Config.UseDNS = false;
            dhcpV6Config.UseDNS = false;
            ipv6AcceptRAConfig.UseDNS = false;
          }
          (if cfg.ipv4Address == null || i > 0 then {
            DHCP = "ipv4";
          } else {
            address = [ cfg.ipv4Address ];
            gateway = [ "192.168.1.1" ];
          })
        ];
      }) cfg.interfaces);
    };

    # Fallback DNS config for systems that don't use resolved
    environment.etc."resolv.conf".text = mkIf (!config.services.resolved.enable)
      (concatMapStringsSep "\n" (s: "nameserver ${s}") dns);
  };
}
