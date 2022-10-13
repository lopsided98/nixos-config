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

  hardware.firmware = singleton (pkgs.runCommandNoCC "mt7610-firmware" {} ''
    mkdir -p "$out/lib/firmware/mediatek"
    cp '${pkgs.linux-firmware}'/lib/firmware/mediatek/mt7610*.bin "$out/lib/firmware/mediatek"
  '');

  # Uplink
  systemd.network.links."30-wl-wan" = {
    matchConfig.Driver = "mt76x0u";
    linkConfig = {
      Name = "wl-wan";
      MACAddressPolicy = "random";
    };
  };
  networking.wireless.scanOnLowSignal = false;
  local.networking.wireless = {
    home = {
      enable = true;
      interfaces = [ "wl-wan" ];
    };
    eduroam = {
      enable = true;
      interfaces = [ "wl-wan" ];
      networkConfig.dhcpV4Config.Anonymize = true;
    };
  };

  # LAN Bridge
  systemd.network = {
    netdevs."30-br-lan".netdevConfig = {
      Name = "br-lan";
      Kind = "bridge";
    };
    networks."30-br-lan" = {
      name = "br-lan";
      address = [ "192.168.2.1/24" ];
      networkConfig = {
        DNS = [ "192.168.2.1" ];
        DHCPServer = true;
        MulticastDNS = true;
        IPMasquerade = "ipv4";
      };
      dhcpServerConfig = {
        DNS = "129.170.17.4";
        # Reserve space for static IPs
        PoolOffset = 100;
      };
      routes = [ { routeConfig = {
        Destination = "192.168.1.1/24";
        Gateway = "192.168.2.2";
      }; } ];
    };
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
    # Dartmouth DNS
    servers = [ "129.170.17.4" ];
    extraConfig = ''
      interface=br-lan
      bind-interfaces
      no-resolv
      server=/benwolsieffer.com/192.168.1.2
    '';
  };

  networking.hostName = "Roomba"; # Define your hostname.

  environment.systemPackages = with pkgs; [ wavemon aircrack-ng iperf3 ];

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
