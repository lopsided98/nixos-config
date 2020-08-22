{ lib, config, pkgs, secrets, ... }:

with lib;

let
  rosPkgs = config.services.ros.pkgs;
in {
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
    <nix-ros-overlay/modules>
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

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="US"
  '';
  hardware.firmware = [ pkgs.wireless-regdb ];

  local.networking.wireless.home = {
    enable = true;
    interface = "wlan0";
  };
  services.resolved.extraConfig = "MulticastDNS=yes";
  systemd.network.networks."30-home".networkConfig.MulticastDNS = "yes";

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
    distro = "melodicPython3";
    overlays = [
      (import ~/Documents/School/Thesis/ros/catkin_ws)
      (self: super: {
        # Remove wxPython dependency, only needed for GUI
        actionlib = super.actionlib.override {
          pythonPackages = self.pythonPackages // { wxPython = null; };
        };
      })
    ];

    systemPackages = p: with p; [ rosbash roslaunch rostopic sailboat-navigation ];

    nodes.sailboat-planner = {
      package = "sailboat_navigation";
      node = "sailboat_planner_node";
      params = {
        _map_file = "/var/lib/ros/map.wkt";
        _wind_direction_sensor_std_dev = "1.0";
      };
    };

    launchFiles.mavros-sailboat = {
      package = "mavros_sailboat";
      launchFile = "mavros_sailboat.launch";
      args.fcu_url = "/dev/ttyAMA0:921600";
    };
  };

  # ROS needs lots of ports
  networking.firewall.enable = false;

  systemd.secrets.sshd = {
    units = [ "sshd@.service" ];
    # Prevent first connection from failing due to decryption taking too long
    lazy = false;
    files = mkMerge [
      (secrets.mkSecret secrets.ragazza.ssh.hostRsaKey {})
      (secrets.mkSecret secrets.ragazza.ssh.hostEd25519Key {})
    ];
  };
}
