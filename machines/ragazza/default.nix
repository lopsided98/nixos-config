{ lib, config, pkgs, inputs, secrets, ... }:

with lib;

let
  rosPkgs = config.services.ros.pkgs;
in {
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi = {
    version = 0;
    enableWirelessFirmware = true;
  };
  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0x4454ef4a";
    rootPartitionUUID = "26d7843f-5484-4504-9df0-3fd6b808a157";
  };

  boot = {
    loader.raspberryPi = {
      enable = true;
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

  services.udev.extraRules = ''
    # Disable power saving (causes network hangs every few seconds)
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name set power_save off"
    # Create virtual AP
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name interface add ap0 type __ap"
  '';

  services.hostapd = {
    enable = true;
    radios.ap0 = {
      wifi4.capabilities = [ "HT40" "SHORT-GI-20" "DSSS_CCK-40" ];
      networks.ap0 = {
        ssid = config.networking.hostName;
        authentication = {
          mode = "wpa2-sha256";
          wpaPskFile = secrets.getSystemdSecret "hostapd" secrets.ragazza.hostapd.wpaPsk;
        };
      };
    };
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
          IPv6SendRA = true;
          MulticastDNS = true;
        };
        dhcpServerConfig = {
          EmitDNS = false;
          EmitNTP = false;
        };
        ipv6SendRAConfig.EmitDNS = false;
      };
      "30-home".networkConfig.MulticastDNS = "yes";
    };
  };
  local.networking.wireless.home = {
    enable = true;
    interfaces = [ "wlan0" ];
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

  # chronyd -s can do something similar, but this runs earlier
  services.fakeHwClock.enable = true;

  services.chrony = {
    enable = true;
    initstepslew = {
      enabled = true;
      threshold = 30;
    };
    extraConfig = ''
      # Pixhawk GPS time from ntpd_driver ROS node. Owned by root:root so we
      # have to make it world writable to allow ntpd_driver to write to it
      # Transmission delays usually cause it to be ~60-80 ms off NTP time (no
      # idea if this will stay constant over time)
      refclock SHM 0:perm=0666 delay 0.5 offset 0.070 refid GPS

      # Allow GPS to step clock
      makestep 30 3
    '';
  };

  services.ros = {
    enable = true;
    distro = "noetic";
    overlays = [
      inputs.ros-sailing.rosOverlay
      (rosSelf: rosSuper: {
        ntpd-driver = rosSelf.callPackage ./ntpd-driver.nix { };
      })
    ];

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

    nodes = {
      wind-estimator = {
        package = "sailboat_navigation";
        node = "wind_estimator_node";
        params = {
          _map_file = "/var/lib/ros/map.wkt";
          _direction_std_dev = "2.0";
          _speed_std_dev = "0.5";
          _estimation_window = "200";
        };
      };

      ntpd-driver = {
        package = "ntpd_driver";
        node = "shm_driver";
        params = {
          _shm_unit = "0";
          _time_ref_topic = "/mavros/time_reference";
        };
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
