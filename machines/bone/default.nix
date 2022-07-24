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

  hardware.firmware = singleton (pkgs.runCommand "mt7610e-firmware" {} ''
    mkdir -p "$out/lib/firmware/mediatek"
    cp '${pkgs.linux-firmware}'/lib/firmware/mediatek/mt7610e.bin "$out/lib/firmware/mediatek"
  '');

  local.networking.home = {
    enable = true;
    interfaces = [ "eth0" ];
  };
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
    extraConfig = ''
      wpa=2
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.bone.hostapd.wpaPsk}
    '';
  };
  systemd.network = {
    enable = true;
    networks."30-ap" = {
      name = "wlan0";
      address = [ "192.168.2.1/24" ];
      networkConfig = {
        DHCPServer = true;
        IPMasquerade = "yes";
        MulticastDNS = true;
      };
      # WL1837 driver doesn't accept multicast traffic in AP mode unless
      # ALLMULTI is enabled.
      # https://patchwork.kernel.org/project/linux-wireless/patch/20170209143728.22831-1-i-hunter1@ti.com/
      linkConfig.AllMulticast = true;
    };
  };

  networking.hostName = "bone";

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.bone.ssh.hostEd25519Key; }
    ];
  };

  networking.firewall.interfaces = {
    wlan0.allowedUDPPorts = [
      67 # DHCP
      5353 # mDNS
    ];
    # TODO: Remove at school
    wlan1.allowedUDPPorts = [
      5353 # mDNS
    ];
    eth0.allowedUDPPorts = [
      5353 # mDNS
    ];
  };

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
