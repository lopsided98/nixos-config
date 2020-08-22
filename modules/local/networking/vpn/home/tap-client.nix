{ config, lib, pkgs, secrets, ... }:

with lib;

let
  cfg = config.local.networking.vpn.home.tap.client;
in {

  # Interface

  options.local.networking.vpn.home.tap.client = {
    enable = mkEnableOption "OpenVPN TAP connection to home network";

    interface = mkOption {
      type = types.str;
      default = "vpn0";
      description = "Network interface to use for VPN.";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
      description = "DNS server that is used exclusively if the VPN is running.";
    };

    macAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "MAC address of the VPN interface. Leave unset to use the default.";
    };

    certificate = mkOption {
      type = types.path;
      description = "Client certificate file";
    };

    privateKey = mkOption {
      type = types.path;
      description = "Client certificate private key file";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    # Enable OpenVPN client
    services.openvpn.servers.home-tap-client.config = ''
      # Specify that we are a client and that we
      # will be pulling certain config file directives
      # from the server.
      client

      # Use the same setting as you are using on
      # the server.
      # On most systems, the VPN will not function
      # unless you partially or fully disable
      # the firewall for the TUN/TAP interface.
      dev-type tap
      dev ${cfg.interface}

      # Are we connecting to a TCP or
      # UDP server?  Use the same setting as
      # on the server.
      proto udp

      # The hostname/IP and port of the server.
      # You can have multiple remote entries
      # to load balance between the servers.
      remote odroid-xu4.benwolsieffer.com 4294

      # Don't retry resolving, so that the process will exit and remove its
      # interface, causing systemd-networkd to use a DNS server outside of
      # the tunnel. The service will be restarted by systemd.
      resolv-retry 0

      # Most clients don't need to bind to
      # a specific local port number.
      nobind

      # Downgrade privileges after initialization
      user openvpn
      group openvpn

      # Try to preserve some state across restarts.
      persist-key
      persist-tun

      # Wireless networks often produce a lot
      # of duplicate packets.  Set this flag
      # to silence duplicate packet warnings.
      ;mute-replay-warnings

      # SSL/TLS parms.
      # See the server config file for more
      # description.  It's best to use
      # a separate .crt/.key file pair
      # for each client.  A single ca
      # file can be used for all clients.
      ca ${./ca.crt}
      cert ${cfg.certificate}
      key ${cfg.privateKey}

      # Verify server certificate by checking
      # that the certicate has the nsCertType
      # field set to "server".  This is an
      # important precaution to protect against
      # a potential attack discussed here:
      #  http://openvpn.net/howto.html#mitm
      #
      # To use this feature, you will need to generate
      # your server certificates with the nsCertType
      # field set to "server".  The build-key-server
      # script in the easy-rsa folder will do this.
      remote-cert-tls server

      # If a tls-auth key is used on the server
      # then every client must also have the key.
      tls-auth ${secrets.getSecret secrets.vpn.home.hmacKey} 1

      # Select a cryptographic cipher.
      # If the cipher option is used on the server
      # then you must also specify it here.
      cipher AES-256-CBC

      auth SHA512

      # Enable compression on the VPN link.
      # Don't enable this unless it is also
      # enabled in the server config file.
      comp-lzo

      ;link-mtu 1634

      ${optionalString (cfg.macAddress != null) ''
        lladdr ${cfg.macAddress}
      ''}

      # Set log file verbosity.
      verb 3

      # MTU optimization
      fragment 1472
      mssfix 1472
    '';

    systemd.network.networks."50-vpn-home-tap-client" = {
      name = cfg.interface;
      dns = cfg.dns;
      # Make the VPN dns override all others
      domains = ["~."];
      dhcpConfig.UseDNS = false;
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=false
      '';
    };

    # Keep attempting to connect forever
    systemd.services.openvpn-home-tap-client.unitConfig.StartLimitIntervalSec = 0;

    users = {
      users.openvpn = {
        isSystemUser = true;
        description = "OpenVPN user";
        group = "openvpn";
      };
      groups.openvpn = {};
    };

    # Monitor VPN with telegraf
    services.telegraf.inputs.net.interfaces = [ cfg.interface ];

    environment.secrets = secrets.mkSecret secrets.vpn.home.hmacKey {};
  };
}
