{ lib, config, pkgs, inputs, secrets, ... }:

with lib;

let
  rosPkgs = config.services.ros.pkgs;
in {
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi.enableWirelessFirmware = true;
  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0x4454ef4a";
    rootPartitionUUID = "26d7843f-5484-4504-9df0-3fd6b808a157";
  };

  boot = {
    loader.raspberryPi = {
      enable = true;
      version = 0;
      firmwareConfig = ''
        # Use the minimum amount of GPU memory
        gpu_mem=16
      '';
      uboot.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_latest;
  };
  hardware.deviceTree = {
    filter = "bcm2835-rpi-zero-w.dtb";
    # Needs non-cross compiled version to work right. It doesn't actually get
    # built
    kernelPackage = pkgs.linuxPackages_latest.kernel;
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

  services.hostapd = {
    enable = true;
    interface = "ap0";
    ssid = "ragazza";
    extraConfig = ''
      wpa=2
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.ragazza.hostapd.wpaPsk}
    '';
  };

  services.resolved.extraConfig = "MulticastDNS=yes";
  systemd.network = {
    enable = true;
    # Access point
    networks = {
      "30-ap0" = {
        name = "ap0";
        address = [ "10.12.0.1/24" ];
        networkConfig = {
          DHCPServer = true;
          IPv6PrefixDelegation = "yes";
          MulticastDNS = "yes";
        };
        extraConfig = ''
          [DHCPServer]
          EmitDNS=no
          EmitNTP=no

          [IPv6PrefixDelegation]
          EmitDNS=no
        '';
      };
      "30-home".networkConfig.MulticastDNS = "yes";
    };
  };
  local.networking.wireless.home = {
    enable = true;
    interface = "wlan0";
  };

  networking.hostName = "ragazza";

  # Allow access to serial ports
  users.users.ros.extraGroups = [ "dialout" ];

  # Services to enable

  services.openssh = {
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSystemdSecret "sshd" secrets.ragazza.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSystemdSecret "sshd" secrets.ragazza.ssh.hostEd25519Key; }
    ];
  };

  services.fakeHwClock.enable = true;

  services.ros = {
    enable = true;
    distro = "noetic";
    overlays = [ inputs.ros-sailing.rosOverlay ];

    systemPackages = p: with p; [ rosbash roslaunch rostopic sailboat-navigation ];

    launchFiles = {
      mavros-sailboat = {
        package = "mavros_sailboat";
        launchFile = "mavros_sailboat.launch";
        args = {
          fcu_url = "/dev/ttyAMA0:921600";
          gcs_url = "udp://@";
        };
      };

      sailboat-navigation = {
        package = "sailboat_navigation";
        launchFile = "sailboat_navigation.launch";
        args._map_file = "/var/lib/ros/map.wkt";
      };
    };

    nodes.wind-estimator = {
      package = "sailboat_navigation";
      node = "wind_estimator_node";
      params = {
        _map_file = "/var/lib/ros/map.wkt";
        _direction_std_dev = "2.0";
        _speed_std_dev = "0.5";
        _estimation_window = "200";
      };
    };
  };

  # Add debug info to system profile
  environment.enableDebugInfo = true;

  # ROS needs lots of ports
  networking.firewall.enable = false;

  systemd.secrets = {
    sshd = {
      units = [ "sshd@.service" ];
      # Prevent first connection from failing due to decryption taking too long
      lazy = false;
      files = mkMerge [
        (secrets.mkSecret secrets.ragazza.ssh.hostRsaKey {})
        (secrets.mkSecret secrets.ragazza.ssh.hostEd25519Key {})
      ];
    };
    hostapd = {
      units = [ "hostapd.service" ];
      files = secrets.mkSecret secrets.ragazza.hostapd.wpaPsk {};
    };
  };
}
