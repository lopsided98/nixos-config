{ lib, config, pkgs, inputs, secrets, ... }:

with lib;

{
  imports = [
    ../../modules
    ../../modules/local/machine/raspberry-pi.nix
  ];

  local.machine.raspberryPi = {
    version = 4;
    enableWirelessFirmware = true;
  };
  #local.profiles.headless = true;

  sdImage = {
    firmwarePartitionID = "0x38cd60d2";
    rootPartitionUUID = "4f54d50c-b6fb-4917-8e06-e008469bbb37";
    compressImage = false;
  };

  boot = {
    kernelPackages = mkForce pkgs.linuxPackages_rpi4;
    kernelParams = [ "cma=128M" ];
  };

  boot.loader = {
    raspberryPi = {
      enable = true;
      uboot.enable = true;
      firmwareConfig = ''
        enable_uart=1
      '';
    };
    generic-extlinux-compatible.copyKernels = false;
  };
  hardware.deviceTree.overlays = [
    {
      name = "disable-bt";
      dtsFile = ./disable-bt.dts;
    }
    {
      name = "uart3";
      dtsFile = ./uart3.dts;
    }
    {
      name = "imx219";
      dtsFile = ./imx219.dts;
    }
    {
      name = "sph0645lm4h-microphone";
      dtsFile = ./sph0645lm4h-microphone.dts;
    }
  ];

  # WiFi configuration

  services.udev.extraRules = ''
    # Create virtual AP
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan0", RUN+="${pkgs.iw}/bin/iw dev $name interface add ap0 type __ap"
  '';

  # Access point
  services.hostapd = {
    enable = true;
    interface = "ap0";
    ssid = config.networking.hostName;
    extraConfig = ''
      wpa_psk_file=${secrets.getSystemdSecret "hostapd" secrets.twin-otter.hostapd.wpaPsk}
    '';
  };
  systemd.network = {
    enable = true;
    networks = {
      "30-ethernet" = {
        name = "end0";
        DHCP = "ipv4";
        networkConfig.MulticastDNS = true;
      };
      "30-ap0" = {
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
    wait-online = {
      ignoredInterfaces = [ "ap0" ];
      anyInterface = true;
    };
  };
  networking.firewall.interfaces = {
    end0.allowedUDPPorts = [
      5353 # mDNS
    ];
    ap0.allowedUDPPorts = [
      67 # DHCP
      5353 # mDNS
    ];
  };

  local.networking.wireless = {
    apartment = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
    eduroam = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
    home = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  };

  networking.hostName = "twin-otter-4";

  users = {
    users = {
      ben.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEBcPmuNz1myMgMwy3LHzxlxIqQPoh2PXnrz2mKt+Be1 Pixel-4a" ];
      camera = {
        isSystemUser = true;
        description = "Camera user";
        group = "camera";
        extraGroups = [ "video" ];
      };
      # Allow access to serial ports
      ros.extraGroups = [ "dialout" ];
    };
    groups.camera = {};
  };

  environment.systemPackages = with pkgs; [
    v4l-utils
    libcamera-apps
    gst_all_1.gstreamer.bin
    gst_all_1.gstreamer.out
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    libraspberrypi
    strace
  ];

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
      # Time from MAVLink SYSTEM_TIME messages
      refclock SOCK /run/chrony.mavlink.sock delay 0.070 refid MAV

      # Allow MAVLink to step clock
      makestep 30 3
    '';
  };

  systemd.services.chronyd.serviceConfig = let
    mavlinkSocket = "/run/chrony.mavlink.sock";
  in {
    # Remove left over socket from previous run
    ExecStartPre = "'${pkgs.coreutils}'/bin/rm -f '${mavlinkSocket}'";
    # Allow fws_mavros to access socket
    ExecStartPost = pkgs.writeShellScript "setup-mavlink-socket.sh" ''
      while [ ! -e '${mavlinkSocket}' ]; do
        sleep 1
      done
      '${pkgs.coreutils}'/bin/chown ros:ros '${mavlinkSocket}'
    '';
  };

  systemd.services.camera-still = {
    description = "Camera still image capture";
    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      StateDirectory = "camera";
      StateDirectoryMode = "0755";
    };
    script = ''
      image_dir=$(mktemp -d /var/lib/camera/still_$(date +%Y%m%d_%H%M%S)_XXXX)
      chmod +rx "$image_dir"

      ${pkgs.libcamera-apps}/bin/libcamera-still \
        --timeout 0 \
        --timelapse 2000 \
        --rotation 180
        -o "$image_dir/img_%04d.jpg"
    '';
  };

  sound.enable = true;
  systemd.services.camera-video = {
    description = "Camera video capture";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      StateDirectory = "camera";
      StateDirectoryMode = "0755";
    };
    script = ''
      image_dir=$(mktemp -d /var/lib/camera/video_$(date +%Y%m%d_%H%M%S)_XXXX)
      chmod +rx "$image_dir"

      ${pkgs.libcamera-apps}/bin/libcamera-vid \
        --nopreview \
        --timeout 0 \
        --width 1920 \
        --height 1080 \
        --rotation 180 \
        --save-pts "$image_dir/timestamps.txt" \
        --output "$image_dir/video.h264"
    '';
  };

  services.ros2 = {
    enable = true;
    overlays = [ inputs.fixed-wing-sampling.rosOverlay ];

    systemPackages = p: with p; [
      ros2cli
      ros2run
      ros2topic
      ros2node
      ros2multicast
      fws-mavros
    ];

    nodes = {
      fws-mavros = {
        package = "fws_mavros";
        node = "fws_mavros";
        # Don't manage the config with Nix for now so that it is easier to
        # adjust in the field.
        rosArgs = [ "--params-file" "/var/lib/ros/fws_mavros.yaml" ];
      };
    };
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
