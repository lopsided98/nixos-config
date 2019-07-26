{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.vpn.dartmouth;
in {

  # Interface

  options.local.networking.vpn.dartmouth = {
    enable = mkEnableOption "PAN GlobalProtect VPN connection to Dartmouth network";

    interface = mkOption {
      type = types.str;
      default = "vpn-dartmouth";
      description = "Network interface to use for VPN.";
    };

    username = mkOption {
      type = types.str;
      default = "f002w9k";
      description = "VPN username";
    };

    passwordSecret = mkOption {
      type = types.str;
      default = secrets.vpn.dartmouth.password;
      description = "Secret containing VPN password.";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    systemd.network.netdevs."50-dartmouth-vpn" = {
      netdevConfig = {
        Name = cfg.interface;
        Kind = "tun";
      };
      extraConfig = ''
        [Tun]
        User=dartmouth-vpn
        Group=dartmouth-vpn
      '';
    };

    systemd.services.dartmouth-vpn = {
      serviceConfig = {
        User = "dartmouth-vpn";
        Group = "dartmouth-vpn";
        ExecStart = ''
          ${pkgs.openconnect}/bin/openconnect \
            --protocol=gp \
            -u ${cfg.username} \
            -i ${cfg.interface} \
            --non-inter \
            --passwd-on-stdin \
            -s "/run/wrappers/bin/sudo ${pkgs.vpnc}/etc/vpnc/vpnc-script" \
            vpn-linux-split.dartmouth.edu
        '';
        StandardInput = "file:${secrets.getSecret cfg.passwordSecret}";
        StandardOutput = "journal";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Allow openconnect to execute vpnc-script as root
    security.sudo = {
      enable = true;
      extraConfig = with pkgs; ''
        Defaults:dartmouth-vpn secure_path="${makeBinPath [ iproute coreutils gnugrep gnused nettools ]}"
        # openconnect passes information in environment variables
        Defaults:dartmouth-vpn !env_reset
        dartmouth-vpn ALL=(root) NOPASSWD: ${vpnc}/etc/vpnc/vpnc-script *
      '';
    };

    users = {
      users.dartmouth-vpn = {
        isSystemUser = true;
        description = "Dartmouth VPN user";
        group = "dartmouth-vpn";
      };
      groups.dartmouth-vpn = {};
    };

    # Monitor VPN with telegraf
    services.telegraf.inputs.net.interfaces = [ cfg.interface ];

    environment.secrets = secrets.mkSecret cfg.passwordSecret {
      user = "dartmouth-vpn";
    };
  };
}
