{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.openvpnClientHomeNetwork;
in {

  # Interface

  options.modules.openvpnClientHomeNetwork = {
    enable = mkEnableOption "OpenVPN connection to home network";

    interface = mkOption {
      type = types.str;
      default = "vpn0";
      description = "Network interface to use for VPN.";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
      description = "DNS server that is used exclusively if the VPN is running.";
    };

    macAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "MAC address of the VPN interface. Leave empty to use the default.";
    };
  };

  # Implementation

  config = mkIf cfg.enable {
    # Enable OpenVPN client
    services.openvpn.servers = {
      client = {
        config = ''
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

          # Choose a random host from the remote
          # list for load-balancing.  Otherwise
          # try hosts in the order specified.
          ;remote-random

          # Keep trying indefinitely to resolve the
          # host name of the OpenVPN server.  Very useful
          # on machines which are not permanently connected
          # to the internet such as laptops.
          resolv-retry infinite

          # Most clients don't need to bind to
          # a specific local port number.
          nobind

          # Downgrade privileges after initialization
          user nobody
          group nobody

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
          ca /var/lib/openvpn/ca.crt
          cert /var/lib/openvpn/${config.networking.hostName}.crt
          key /var/lib/openvpn/${config.networking.hostName}.key

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
          tls-auth /var/lib/openvpn/ta.key 1

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

          # Silence repeating messages
          ;mute 20

          # MTU optimization
          fragment 1472
          mssfix 1472
        '';
      };
    };

    systemd.network = {
      networks.openvpn-client-home-network = {
        name = cfg.interface;
        dhcpConfig.UseDNS = false;
        dns = cfg.dns;
        # Make the VPN dns override all others
        domains = ["~."];
      };
    };

    # Monitor VPN with telegraf
    services.telegraf.inputs.net.interfaces = [ cfg.interface ];
  };
}
