{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dnsupdate;
  
  # Combine args with include files
  argsString = a: let
    aJson = builtins.toJSON a.args;
    includeArgList = mapAttrsToList (k: f: "\"${k}\": !include_text \"${f}\"") a.includeArgs;
  in (builtins.substring 0 ((builtins.stringLength aJson) - 1) aJson) + (if builtins.length includeArgList != 0 then "," else "") +
    (concatStringsSep "," includeArgList) + "}";
  
  addressProviderProtocolType = types.submodule {
    options = {
      type = mkOption {
        type = types.str;
      };
      args = mkOption {
        type = types.attrs;
        default = {};
      };
      includeArgs = mkOption {
        type = types.attrs;
        default = {};
      };
    };
  };
  
  addressProviderType = types.submodule {
    options = listToAttrs (map (n: nameValuePair n (mkOption {
      type = types.nullOr addressProviderProtocolType;
      default = null;
    })) ["ipv4" "ipv6" "all"]);
  };
  
  dnsServiceType = types.submodule {
    options = {
      type = mkOption {
        type = types.str;
      };
      addressProvider = mkOption {
        type = types.nullOr addressProviderType;
        default = null;
      };
      args = mkOption {
        type = types.attrs;
        default = {};
      };
      includeArgs = mkOption {
        type = types.attrs;
        default = {};
      };
    };
  };
  
  addressProviderProtocol = a: if a == null then "None" else '' {
    "type": "${a.type}",
    "args": ${argsString a}
  } '';
  
  addressProvider = a: if (a.ipv4 != null || a.ipv6 != null) then '' {
    ${if a.ipv4 != null then "\"ipv4\": ${addressProviderProtocol a.ipv4}," else ""}
    ${if a.ipv6 != null then "\"ipv6\": ${addressProviderProtocol a.ipv6}" else ""}
  } '' else addressProviderProtocol a.all;
  
  addressProviderCheck = a: {
    assertion = (a == null) || ((a.all != null && a.ipv4 == null && a.ipv6 == null) || ((a.ipv4 != null || a.ipv6 != null) && a.all == null));
    message = "IPv4 or IPv6 address provider cannot be specified with a multiprotocol address provider";
  };
  
  dnsService = d: '' {
    "type": "${d.type}",
    ${if (d.addressProvider != null) then "\"address_provider\": ${addressProvider d.addressProvider}," else ""}
    "args": ${argsString d}
  }'';
  
  configFile = cfg: ''
    {
    ${if cfg.addressProvider != null then "\"address_provider\": ${addressProvider cfg.addressProvider}," else ""}
    
    "dns_services": [
      ${concatMapStringsSep ",\n" dnsService cfg.dnsServices}
    ],
    
    "cache_file": "${cfg.cacheFile}"
    }
  '';
in {

  # Interface

  options.services.dnsupdate = {
    enable = mkEnableOption "periodic update of dynamic DNS services";

    interval = mkOption {
      type = types.str;
      default = "*:0/10";
      example = "hourly";
      description = ''
        Run dnsupdate at this interval. The default is to run every ten minutes.

        The format is described in
        <citerefentry><refentrytitle>systemd.time</refentrytitle>
        <manvolnum>7</manvolnum></citerefentry>.
      '';
    };
    
    addressProvider = mkOption {
      type = addressProviderType;
      default = null;
      description = ''
        Service for obtaining the IP address to assign to a domain.
      '';
    };
    
    dnsServices = mkOption {
      type = types.listOf dnsServiceType;
      default = [];
      description = ''
        Service used to update a domain.
      '';
    };
    
    cacheFile = mkOption {
      type = types.path;
      default = "/var/cache/dnsupdate/dnsupdate.cache";
      description = "Cache file for keeping track of addresses.";
    };

  };
  
  # Implementation
  
  config = mkIf cfg.enable {
    assertions = [(addressProviderCheck cfg.addressProvider)] ++
      (map (d: addressProviderCheck d.addressProvider) cfg.dnsServices);
  
    users.extraUsers.dnsupdate = {
      isSystemUser = true;
      description = "dnsupdate user";
    };
  
    systemd.services.dnsupdate = {
      description = "Run dynamic DNS update client";
      serviceConfig = {
        Type = "oneshot";
        User = "dnsupdate";
        ExecStart = "${pkgs.dnsupdate}/bin/dnsupdate ${pkgs.writeText "dnsupdate.conf" (configFile cfg)}";
      };
    };

    systemd.timers.dnsupdate = {
      description = "Dynamic DNS update timer";
      partOf = [ "dnsupdate.service" ];
      wantedBy = [ "timers.target" ];
      timerConfig.OnCalendar = cfg.interval;
    };
  };
}
