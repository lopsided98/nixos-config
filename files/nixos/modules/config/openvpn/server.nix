{ config, pkgs, secrets, ... }: {

  imports = [
  ];

  # NAT configuration for tun VPN
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nat = {
    enable = true;
    externalInterface = "br0";
    internalInterfaces  = [ "vpn1" ];
  };
  
  # Bridge configuration for tap VPN
  systemd.network = {
    netdevs = {
      br0.netdevConfig = {
        Name = "br0";
        Kind = "bridge";
      };
      vpn0.netdevConfig = {
        Name = "vpn0";
        Kind = "tap";
      };
    };
    networks.eth0 = {
      name = "eth0";
      networkConfig.Bridge = "br0";
    };
  };

  # Enable OpenVPN client
  services.openvpn.servers = let
    dataDir = "/var/lib/openvpn";

    common = ''
      # Use UDP
      proto udp

      # SSL/TLS root certificate (ca), certificate
      # (cert), and private key (key).  Each client
      # and the server must have their own cert and
      # key file.  The server and all clients will
      # use the same ca file.
      #
      # See the "easy-rsa" directory for a series
      # of scripts for generating RSA certificates
      # and private keys.  Remember to use
      # a unique Common Name for the server
      # and each of the client certificates.
      #
      # Any X509 key management system can be used.
      # OpenVPN can also use a PKCS #12 formatted key file
      # (see "pkcs12" directive in man page).
      ca ${./ca.crt}
      cert ${./. + "/${config.networking.hostName}.crt"}
      key ${secrets.getSecret secrets."${config.networking.hostName}".openvpn.privateKey}

      # Diffie hellman parameters.
      # Generate your own with:
      #   openssl dhparam -out dh2048.pem 2048
      dh ${./dh.pem}

      # Network topology
      topology subnet

      # Ping every 10 seconds, assume connection is dead
      # if no response is heard in 30 seconds
      keepalive 10 30

      # For extra security beyond that provided
      # by SSL/TLS, create an "HMAC firewall"
      # to help block DoS attacks and UDP port flooding.
      #
      # Generate with:
      #   openvpn --genkey --secret ta.key
      #
      # The server and each client must have
      # a copy of this key.
      # The second parameter should be '0'
      # on the server and '1' on the clients.
      tls-auth ${secrets.getSecret secrets.openvpn.hmacKey} 0 # This file is secret
      tls-version-min 1.2
      tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-256-CBC-SHA:TLS-DHE-RSA-WITH-CAMELLIA-256-CBC-SHA:TLS-DHE-RSA-WITH-AES-128-CBC-SHA:TLS-DHE-RSA-WITH-CAMELLIA-128-CBC-SHA

      # Select a cryptographic cipher.
      # This config item must be copied to
      # the client config file as well.
      cipher AES-256-CBC

      auth SHA512

      # Enable compression on the VPN link.
      # If you enable it here, you must also
      # enable it in the client config file.
      comp-lzo

      # Drop root privelges after setup
      user nobody
      group nobody

      # The persist options will try to avoid
      # accessing certain resources on restart
      # that may no longer be accessible because
      # of the privilege downgrade.
      persist-key
      persist-tun

      # Set the appropriate level of log
      # file verbosity.
      #
      # 0 is silent, except for fatal errors
      # 4 is reasonable for general usage
      # 5 and 6 can help to debug connection problems
      # 9 is extremely verbose
      verb 3

      # Silence repeating messages.  At most 20
      # sequential messages of the same message
      # category will be output to the log.
      ;mute 20
    '';
  in {
    tap.config = ''
      ${common}

      port 4294

      # Create tap device named vpn0
      dev-type tap
      dev vpn0

      # Configure server mode for ethernet bridging
      # using a DHCP-proxy, where clients talk
      # to the OpenVPN server-side DHCP server
      # to receive their IP address allocation
      # and DNS server addresses.  You must first use
      # your OS's bridging capability to bridge the TAP
      # interface with the ethernet NIC interface.
      # Note: this mode only works on clients (such as
      # Windows), where the client-side TAP adapter is
      # bound to a DHCP client.
      server-bridge

      # Uncomment this directive to allow different
      # clients to be able to "see" each other.
      # By default, clients will only see the server.
      # To force clients to only see the server, you
      # will also need to appropriately firewall the
      # server's TUN/TAP interface.
      ;client-to-client

      # MTU optimization
      fragment 1472
    '';
    tun.config = let
      subnet = "10.54.0";
      clientConfigDir = pkgs.linkFarm "openvpn-client-config" [
        rec {
          name = "Sam LaRussa";
          path = pkgs.writeText "openvpn-SamLaRussa-client-config" ''
            ifconfig-push ${subnet}.10 255.255.255.0
          '';
        }
      ];
    in ''
      ${common}

      port 4295

      # Tun interface
      dev-type tun
      dev vpn1

      # Configure server mode and supply a VPN subnet
      # for OpenVPN to draw client addresses from.
      # The server will take 10.8.0.1 for itself,
      # the rest will be made available to clients.
      # Each client will be able to reach the server
      # on 10.54.0.1.
      server ${subnet}.0 255.255.255.0

      # Maintain a record of client <-> virtual IP address
      # associations in this file.  If OpenVPN goes down or
      # is restarted, reconnecting clients can be assigned
      # the same virtual IP address from the pool that was
      # previously assigned.
      ifconfig-pool-persist ${dataDir}/ip-pool-tun.txt

      # If enabled, this directive will configure
      # all clients to redirect their default
      # network gateway through the VPN, causing
      # all IP traffic such as web browsing and
      # and DNS lookups to go through the VPN
      # (The OpenVPN server machine may need to NAT
      # or bridge the TUN/TAP interface to the internet
      # in order for this to work properly).
      push "redirect-gateway def1 bypass-dhcp"
      push "dhcp-option DNS 192.168.1.2"

      # Uncomment this directive to allow different
      # clients to be able to "see" each other.
      # By default, clients will only see the server.
      # To force clients to only see the server, you
      # will also need to appropriately firewall the
      # server's TUN/TAP interface.
      ;client-to-client

      client-config-dir ${clientConfigDir}
    '';
  };
  
  networking.firewall = {
    extraCommands = ''
      # Deny Sam access to the router
      iptables -F FORWARD || true
      iptables -X FORWARD || true
      iptables -A FORWARD -i vpn1 -s 10.54.0.10 -d 192.168.1.2 -j ACCEPT
      iptables -A FORWARD -i vpn1 -s 10.54.0.10 -d 192.168.1.0/24 -j REJECT
    '';
    allowedUDPPorts = [ 4294 4295 ];
  };
  
  environment.secrets = 
    secrets.mkSecret secrets.openvpn.hmacKey {} //
    secrets.mkSecret secrets."${config.networking.hostName}".openvpn.privateKey {};
}
