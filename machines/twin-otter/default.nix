{ lib, config, pkgs, inputs, secrets, ... }:

with lib;

let
  rosPkgs = config.services.ros.pkgs;
in {
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  # Enable cross-compilation
  local.system.buildSystem.system = "x86_64-linux";

  local.machine.raspberryPi.enableWirelessFirmware = true;
  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0x87b76516";
    rootPartitionUUID = "c1f10940-ab67-43df-915f-2eab9432f62b";
    compressImage = false;
  };

  boot.loader.raspberryPi = {
    enable = true;
    version = 0;
    firmwareConfig = ''
      # Use the minimum amount of GPU memory
      gpu_mem=16
    '';
    uboot.enable = true;
  };
  hardware.deviceTree = {
    filter = "bcm2835-rpi-zero-w.dtb";
    overlays = [
      {
        name = "disable-bt";
        dtsFile = ./disable-bt.dts;
      }
      {
        name = "disable-stdout";
        dtsFile = ./disable-stdout.dts;
      }
    ];
  };

  # WiFi configuration

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"
  '';
  hardware.firmware = [ pkgs.wireless-regdb ];

  services.udev.extraRules = ''
    # Disable power saving (causes network hangs every few seconds)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
    # Create virtual AP
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name interface add ap0 type __ap"
  '';

  services.resolved.extraConfig = "MulticastDNS=yes";

  # Access point
  services.hostapd = {
    enable = true;
    interface = "ap0";
    ssid = config.networking.hostName;
    extraConfig = ''
      wpa=2
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.twin-otter.hostapd.wpaPsk}
    '';
  };
  systemd.network = {
    enable = true;
    networks."30-ap0" = {
      name = "ap0";
      address = [ "10.12.0.1/24" ];
      networkConfig = {
        DHCPServer = true;
        MulticastDNS = true;
      };
      dhcpServerConfig = {
        EmitDNS = false;
        EmitNTP = false;
      };
    };
  };
  # DHCP server
  networking.firewall.allowedUDPPorts = [ 67 ];

  # eduroam
  local.networking.wireless.eduroam = {
    enable = true;
    interface = "wlan0";
  };

  networking.hostName = "twin-otter";

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.twin-otter.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.twin-otter.ssh.hostEd25519Key; }
    ];
  };

  # chronyd -s can do something similar, but this runs earlier
  services.fakeHwClock.enable = true;

  services.chrony = {
    enable = true;
    initstepslew = {
      enabled = true;
      threshold = 30;
    };
    extraConfig = ''
      # GPS time from ntpd_driver ROS node. Owned by root:root so we have to
      # make it world writable to allow ntpd_driver to write to it. Transmission
      # delays usually cause it to be ~60-80 ms off NTP time (no idea if this
      # will stay constant over time)
      refclock SHM 0:perm=0666 delay 0.5 offset 0.070 refid GPS

      # Allow GPS to step clock
      makestep 30 3
    '';
  };

  systemd.secrets = {
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.twin-otter.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.twin-otter.ssh.hostEd25519Key {})
      ];
    };
    hostapd = {
      units = [ "hostapd.service" ];
      files = secrets.mkSecret secrets.twin-otter.hostapd.wpaPsk {};
    };
  };
}
