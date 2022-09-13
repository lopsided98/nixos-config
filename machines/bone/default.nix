{ lib, config, pkgs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/beagle-bone
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0xce102799";
    rootPartitionUUID = "de4bdabd-5b30-4339-9168-14fbd944184f";
    compressImage = false;
  };

  local.machine.beagleBone.enableWirelessCape = true;

  hardware.firmware = singleton (pkgs.runCommand "mt7610-firmware" {} ''
    mkdir -p "$out/lib/firmware/mediatek"
    cp '${pkgs.linux-firmware}'/lib/firmware/mediatek/mt7610*.bin "$out/lib/firmware/mediatek"
  '');

  local.networking.wireless = {
    home = {
      enable = true;
      interfaces = [ "wlan1" ];
    };
    eduroam = {
      enable = true;
      interfaces = [ "wlan1" ];
    };
  };

  # Access point
  services.hostapd = {
    enable = true;
    interface = "wlan0";
    ssid = "Illuin";
    countryCode = "US";
    extraConfig = ''
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.bone.hostapd.wpaPsk}
    '';
  };

  systemd.network = {
    enable = true;
    netdevs."50-br-lan" = {
      netdevConfig = {
        Name = "br-lan";
        Kind = "bridge";
      };
      # Ethernet driver requires default_pvid to be 0 to be bridged
      extraConfig = ''
        [Bridge]
        DefaultPVID=none
      '';
    };
    networks = {
      "30-br-lan" = {
        name = "br-lan";
        address = [ "192.168.2.1/24" ];
        networkConfig = {
          DHCPServer = true;
          IPMasquerade = "ipv4";
          MulticastDNS = true;
        };
        # Hardcode Dartmouth DNS so clients recieve it over DHCP even if the
        # uplink interface is not connected
        dhcpServerConfig.DNS = "129.170.17.4";
      };
      "30-ap" = {
        name = "wlan0";
        # Wait for hostapd to switch to AP mode
        matchConfig.WLANInterfaceType = "ap";
        networkConfig.Bridge = "br-lan";
        # WL1837 driver doesn't accept multicast traffic in AP mode unless
        # ALLMULTI is enabled.
        # https://patchwork.kernel.org/project/linux-wireless/patch/20170209143728.22831-1-i-hunter1@ti.com/
        linkConfig.AllMulticast = true;
      };
      "30-ethernet" = {
        name = "eth0";
        networkConfig.Bridge = "br-lan";
      };
    };
  };

  networking.hostName = "bone";

  environment.systemPackages = with pkgs; [ aircrack-ng iperf3 ];

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostEd25519Key; }
    ];
  };

  networking.firewall.interfaces.br-lan.allowedUDPPorts = [
    67 # DHCP
    5353 # mDNS
  ];

  systemd.secrets = {
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.bone.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.bone.ssh.hostEd25519Key {})
      ];
    };
    hostapd = {
      units = [ "hostapd.service" ];
      files = secrets.mkSecret secrets.bone.hostapd.wpaPsk {};
    };
  };
}
