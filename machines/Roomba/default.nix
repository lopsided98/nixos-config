{ lib, config, pkgs, inputs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi = {
    version = 3;
    enableWirelessFirmware = true;
  };

  sdImage = {
    firmwarePartitionID = "0x0980df14";
    rootPartitionUUID = "b12d092c-fc79-4d6d-8879-0be220bc1ad2";
  };

  boot = {
    loader = {
      raspberryPi = {
        enable = true;
        version = 3;
        uboot.enable = true;
      };
      generic-extlinux-compatible.copyKernels = false;
    };
    kernelPackages = mkForce pkgs.linuxPackages_5_15;
  };

  hardware.firmware = singleton (pkgs.runCommand "mt7610-firmware" {} ''
    mkdir -p "$out/lib/firmware/mediatek"
    cp '${pkgs.linux-firmware}'/lib/firmware/mediatek/mt7610*.bin "$out/lib/firmware/mediatek"
  '');

  # FIXME: conntrack seems to break policy routing
  networking.firewall.enable = false;

  systemd.network.config.routeTables = {
    wl-wan0 = 9375;
    wl-wan1 = 9376;
    wg0 = 9377;
  };

  # Uplink
  systemd.network.links."30-wl-wan0" = {
    matchConfig = {
      Driver = "mt76x0u";
      PermanentMACAddress = "00:c0:ca:b1:07:ed";
    };
    linkConfig = {
      Name = "wl-wan0";
      MACAddressPolicy = "random";
    };
  };
  networking.wireless.scanOnLowSignal = false;
  local.networking.wireless = {
    home = {
      enable = true;
      interfaces = [ "wl-wan0" ];
    };
    eduroam = {
      enable = true;
      interfaces = [ "wl-wan0" ];
      networkConfig = {
        dhcpV4Config = {
          Anonymize = true;
          RouteTable = 9375; # wl-wan0
        };
        # Use this uplink as the default route for normal traffic
        routingPolicyRules = [ { routingPolicyRuleConfig = {
          Table = "wl-wan0";
          Family = "both";
          Priority = 101;
        }; } ];
      };
    };
  };

  # Backup uplink
  systemd.network.links."30-wl-wan1" = {
    matchConfig = {
      Driver = "mt76x0u";
      PermanentMACAddress = "04:d4:c4:5e:fe:28";
    };
    linkConfig.Name = "wl-wan1";
  };
  local.networking.wireless.xfinitywifi = {
    enable = true;
    interfaces = [ "wl-wan1" ];
  };
  systemd.network.networks."30-xfinitywifi" = {
    dhcpV4Config.RouteTable = 9376; # wl-wan1
    ipv6AcceptRAConfig.RouteTable = 9376; # wl-wan1
    routingPolicyRules = [
      # Allow traffic from systemd-resolved that is specifically sent to this
      # interface. This allows it to resolve the VPN server IP address.
      { routingPolicyRuleConfig = {
        Table = "wl-wan1";
        User = "systemd-resolve";
        OutgoingInterface = "wl-wan1";
        Family = "both";
        Priority = 102;
      }; }
      # Only route WireGuard traffic to this uplink
      { routingPolicyRuleConfig = {
        Table = "wl-wan1";
        FirewallMark = config.local.networking.vpn.home.wireGuard.client.firewallMark;
        Family = "both";
        Priority = 104;
      }; }
    ];
  };
  local.networking.vpn.home.wireGuard.client = {
    enable = true;
    publicKey = "9cB7ABTbznTdTjONO3NrmLxgUYtefrIAuHlquwy9njU=";
    privateKeySecret = secrets.Roomba.vpn.wireGuardPrivateKey;
    gatewayRouteConfig.Table = "wg0";
    # Use VPN as secondary default route, if the main uplink table is empty.
    # Also, ensure that outgoing WireGuard traffic doesn't get looped through
    # the VPN.
    networkConfig.routingPolicyRules = [ { routingPolicyRuleConfig = {
      Table = "wg0";
      InvertRule = true;
      FirewallMark = config.local.networking.vpn.home.wireGuard.client.firewallMark;
      Family = "both";
      Priority = 103;
    }; } ];
    persistentKeepalive = true;
  };

  # LAN Bridge
  systemd.network.netdevs."30-br-lan".netdevConfig = {
    Name = "br-lan";
    Kind = "bridge";
  };
  systemd.network.networks."30-br-lan" = {
    name = "br-lan";
    address = [ "192.168.2.1/24" ];
    networkConfig = {
      DHCPServer = true;
      MulticastDNS = true;
      IPMasquerade = "ipv4";
    };
    dhcpServerConfig = {
      DNS = "192.168.2.1";
      # Reserve space for static IPs
      PoolOffset = 100;
    };
    # Increase the main table priority, to allows others to be added at lower
    # priority
    routingPolicyRules = [ { routingPolicyRuleConfig = {
      Table = "main";
      Family = "both";
      Priority = 100;
    }; } ];
  };
  networking.firewall.interfaces.br-lan.allowedUDPPorts = [
    53 # DNS
    67 # DHCP
    5353 # mDNS
  ];

  # Ethernet
  systemd.network.networks."30-ethernet" = {
    name = "eth0";
    networkConfig.Bridge = "br-lan";
  };

  # Access point
  services.hostapd = {
    enable = true;
    interface = "wl-lan";
    ssid = "Illuin";
    countryCode = "US";
    extraConfig = ''
      wpa=2
      ieee80211w=0
      wpa_key_mgmt=WPA-PSK
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.Roomba.hostapd.wpaPsk}
    '';
  };
  systemd.network.links."30-wl-lan" = {
    matchConfig.Driver = "brcmfmac";
    linkConfig.Name = "wl-lan";
  };
  systemd.network.networks."30-ap" = {
    name = "wl-lan";
    # Wait for hostapd to switch to AP mode
    matchConfig.WLANInterfaceType = "ap";
    networkConfig.Bridge = "br-lan";
  };

  # DNS server
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = false;
    alwaysKeepRunning = true;
    settings = {
      interface = "br-lan";
      bind-interfaces = true;
      no-resolv = true;
      server = [
        "9.9.9.10"
        "149.112.112.10"
        "2620:fe::10"
        "2620:fe::fe:10"
        "/dartmouth.edu/129.170.17.4"
        "/benwolsieffer.com/2601:18c:8380:74b0:ba27:ebff:fe5e:6b6e"
      ];
      # Need to allow access to DNS server from VPN IPv4
      # ++ map (s: "/benwolsieffer.com/${s}") config.local.networking.home.dns;

      # VPN server replies back from its VPN ip even if its normal internal IP
      # was the destination, so override its DNS entries to use its VPN IP.
      address = [
        "/odroid-xu4.benwolsieffer.com/${config.local.networking.vpn.home.wireGuard.server.ipv4Address}"
        "/odroid-xu4.benwolsieffer.com/${config.local.networking.vpn.home.wireGuard.server.ipv6Address}"
      ];
    };
  };

  networking.hostName = "Roomba"; # Define your hostname.

  environment.systemPackages = with pkgs; [
    wavemon
    aircrack-ng
    iperf3
    tcpdump
    nftables
    ldns
  ];

  # List services that you want to enable:

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.Roomba.ssh.hostRsaKey; }
    { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.Roomba.ssh.hostEd25519Key; }
  ];

  # Save/restore time
  services.fakeHwClock.enable = true;

  # Enable SD card TRIM
  services.fstrim.enable = true;

  systemd.secrets = {
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.Roomba.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.Roomba.ssh.hostEd25519Key {})
      ];
    };
    hostapd = {
      units = [ "hostapd.service" ];
      files = secrets.mkSecret secrets.Roomba.hostapd.wpaPsk {};
    };
  };
}
