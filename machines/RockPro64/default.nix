{ lib, config, pkgs, secrets, ... }:

with lib;

let
  address = "192.168.1.7";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../modules
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
  };

  hardware.firmware = let
    libreElecFirmware = pkgs.fetchFromGitHub {
      owner = "LibreELEC";
      repo = "brcmfmac_sdio-firmware";
      rev = "afc477e807c407736cfaff6a6188d09197dfbceb";
      hash = "sha256-544zEHIBMKXtIAp7sSLolPChCIFQw+xVin1/Ki1MliI=";
    };
  in [ 
    (pkgs.runCommandNoCC "bcm4359-firmware" {} ''
      mkdir -p "$out/lib/firmware/brcm"
      cp '${libreElecFirmware}'/{BCM4359*.hcd,brcmfmac4359-sdio*}  "$out/lib/firmware/brcm"
    '')
    (pkgs.runCommandNoCC "mt7610-firmware" {} ''
      mkdir -p "$out/lib/firmware/mediatek"
      cp '${pkgs.linux-firmware}'/lib/firmware/mediatek/mt7610*.bin "$out/lib/firmware/mediatek"
    '')
  ];

  # Uplink
  systemd.network.links."30-wl-wan" = {
    matchConfig.Driver = "mt76x0u";
    linkConfig = {
      Name = "wl-wan";
      MACAddressPolicy = "random";
    };
  };
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
        DHCPServer = true;
        MulticastDNS = true;
      };
      # Hardcode Dartmouth DNS so clients recieve it over DHCP even if the
      # uplink interface is not connected
      dhcpServerConfig.DNS = "129.170.17.4";
    };
  };
  networking.nat = {
    enable = true;
    internalInterfaces = [ "br-lan" ];
    externalInterface = "wl-wan";
  };
  networking.firewall.interfaces.br-lan.allowedUDPPorts = [
    67 # DHCP
    5353 # mDNS
  ];

  # Ethernet
  systemd.network.networks."30-ethernet" = {
    name = "eth0";
    # Use a different MAC address on physical interface, because the normal MAC
    # is used on the VPN in order to get consistent IPs.
    linkConfig.MACAddress = "ba:4b:f9:9b:f1:88";
    networkConfig.Bridge = "br-lan";
  };
  # Work around checksumming bug
  networking.localCommands = ''
    ${pkgs.ethtool}/bin/ethtool -K eth0 rx off tx off
  '';

  # Access point
  services.hostapd = {
    enable = true;
    interface = "wl-lan";
    ssid = "Illuin";
    countryCode = "US";
    extraConfig = ''
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.RockPro64.hostapd.wpaPsk}
    '';
  };
  systemd.network.links."30-wl-lan" = {
    matchConfig.Path = "platform-fe310000.mmc";
    linkConfig = {
      Name = "wl-lan";
      MACAddressPolicy = "random";
    };
  };
  systemd.network.networks."30-ap" = {
    name = "wl-lan";
    # Wait for hostapd to switch to AP mode
    matchConfig.WLANInterfaceType = "ap";
    networkConfig.Bridge = "br-lan";
  };

  # DNS server
  services.dnsmasq = {
    resolveLocalQueries = false;
    alwaysKeepRunning = true;
    servers = [ "129.170.17.4" ];
    extraConfig = ''
      server=/benwolsieffer.com/192.168.1.2
    '';
  };

  # OpenVPN TAP client
  local.networking.vpn.home.tap.client = {
    enable = true;
    macAddress = "b2:5e:ef:50:6a:ff";
    certificate = ./vpn/home/client.crt;
    privateKeySecret = secrets.RockPro64.vpn.home.privateKey;
  };
  systemd.network.networks."50-vpn-home-tap-client" = {
    address = [ "${address}/24" ];
    extraConfig = ''
      [IPv6AcceptRA]
      UseDNS=false
    '';
  };

  networking = {
    hostName = "RockPro64";
    hostId = "67b35626";
  };

  environment.systemPackages = with pkgs; [ aircrack-ng iperf3 ];

  # List services that you want to enable:

  services.openssh = {
    ports = [ 4247 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.RockPro64.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.RockPro64.ssh.hostEd25519Key; }
    ];
  };

  # Save/restore time
  services.fakeHwClock.enable = true;

  # System metrics logging
  local.services.telegraf = {
    enable = true;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.RockPro64.telegraf.influxdbTlsKey;
    };
  };

  local.services.backup = {
    server = {
      enable = true;
      device = "/dev/disk/by-uuid/fea46c86-192a-40e4-a871-ae7f5d9b1840";
    };
    sanoid.enable = true;
    syncthing = {
      virtualHost = "syncthing.rockpro64.benwolsieffer.com";
      certificate = ./syncthing/cert.pem;
      certificateKeySecret = secrets.RockPro64.syncthing.certificateKey;
      httpsCertificate = ./syncthing/https-cert.pem;
      httpsCertificateKeySecret = secrets.RockPro64.syncthing.httpsCertificateKey;
    };
  };

  services.sanoid = {
    datasets = {
      # Each backup node takes its own snapshots of data
      "backup/data" = {
        use_template = [ "backup" ];
        autosnap = true;
        recursive = true;
        process_children_only = true;
      };
      # Prune all backups with one rule
      "backup/backups" = {
        use_template = [ "backup" ];
        recursive = true;
        process_children_only = true;
      };

      # Snapshots of non-ZFS devices that backup to this node
      "backup/backups/P-3400" = {
        use_template = [ "backup" ];
        autosnap = true;
        recursive = true;
      };
    };
  };

  services.syncoid = let
    remote = "backup@hp-z420.benwolsieffer.com";
  in {
    commonArgs = [ "--sshport" "4245" ];
    commands = {
      "backup/backups/P-3400" = {
        target = "${remote}:backup/backups/P-3400";
        recursive = true;
      };
    };
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  systemd.secrets = {
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.RockPro64.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.RockPro64.ssh.hostEd25519Key {})
      ];
    };
    hostapd = {
      units = [ "hostapd.service" ];
      files = secrets.mkSecret secrets.RockPro64.hostapd.wpaPsk {};
    };
  };
}
