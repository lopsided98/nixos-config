{ lib, config, pkgs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.machine.raspberryPi = {
    version = 0;
    enableWirelessFirmware = true;
  };
  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0x2a7208bc";
    rootPartitionUUID = "79cd7c77-b355-4d2b-b1d5-fa9207e944f2";
    compressImage = false;
  };

  boot.loader.raspberryPi = {
    enable = true;
    firmwareConfig = ''
      # Use the minimum amount of GPU memory
      gpu_mem=16
    '';
    uboot.enable = true;
  };

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"
  '';

  services.udev.extraRules = ''
    # Disable power saving (causes network hangs every few seconds)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
  '';

  networking.hostName = "maine-pi";

  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
    networks."OLE AKI" = {
      pskRaw = "ext:MAINE_PSK";
      # WPA-PSK-SHA256 doesn't work on the RPi Zero
      authProtocols = [ "WPA-PSK" "SAE" ];
    };
  };
  local.networking.wireless.passwordFiles =
    singleton (secrets.getSystemdSecret "wpa_supplicant-maine" secrets.maine-pi.wpaSupplicant);

  systemd.network = {
    enable = true;
    networks."30-wlan0" = {
      name = "wlan0";
      DHCP = "ipv4";
      networkConfig.MulticastDNS = "yes";
    };
    networks."50-vpn-home-tap-client".DHCP = "ipv4";
  };
  networking.firewall.interfaces.wlan0.allowedUDPPorts = [ 5353 /* mDNS */ ];

  # Services to enable

  services.openssh = {
    ports = [ 4287 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.maine-pi.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.maine-pi.ssh.hostEd25519Key; }
    ];
  };

  local.networking.vpn.home.tap.client = {
    enable = true;
    certificate = ./vpn/home/client.crt;
    privateKeySecret = secrets.maine-pi.vpn.home.privateKey;
  };

  services.dnsupdate = {
    enable = true;
    addressProvider = {
      ipv4.type = "Web";
    };

    dnsServices = singleton {
      type = "NSUpdate";
      args.hostname = "maine-pi.nsupdate.info";
      includeArgs.secret_key = secrets.getSystemdSecret "dnsupdate" secrets.maine-pi.dnsupdate.secretKey;
    };
  };

  services.watchdog = {
    enable = true;
    watchdogDevice = "/dev/watchdog0";
    watchdogTimeout = 10;
    realtime = true;
  };

  local.services.waterLevelMonitor = {
    enable = true;
    certificateSecret = secrets.maine-pi.waterLevelMonitor.influxdbCertificate;
  };
  services.waterLevelMonitor = {
    influxdb = {
       url = "https://influxdb.benwolsieffer.com:8086";
       database = "maine";
    };
    address = "C6:F8:64:2F:D9:D2";
  };

  systemd.secrets = {
    dnsupdate = {
      files = secrets.mkSecret secrets.maine-pi.dnsupdate.secretKey { user = "dnsupdate"; };
      units = [ "dnsupdate.service" ];
    };
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.maine-pi.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.maine-pi.ssh.hostEd25519Key {})
      ];
    };
    wpa_supplicant-maine = {
      files = secrets.mkSecret secrets.maine-pi.wpaSupplicant { };
      units = [ "wpa_supplicant-wlan0.service" ];
    };
  };
}
