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

  local.machine.raspberryPi = {
    version = 0;
    enableWirelessFirmware = true;
  };
  local.profiles.minimal = true;

  sdImage = {
    firmwarePartitionID = "0x87b76516";
    rootPartitionUUID = "c1f10940-ab67-43df-915f-2eab9432f62b";
    compressImage = false;
  };

  boot.kernelPackages = mkForce pkgs.linuxPackages_rpi0;

  boot.loader.raspberryPi = {
    enable = true;
    version = 0;
    firmwareConfig = ''
      start_x=1
      gpu_mem=128
    '';
    uboot.enable = true;
  };
  hardware.deviceTree = rec {
    name = "bcm2708-rpi-zero-w.dtb";
    filter = name;
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
  networking.firewall.interfaces.ap0.allowedUDPPorts = [
    67 # DHCP
    5353 # mDNS
  ];

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

  networking.hostName = "twin-otter";

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
    gst_all_1.gstreamer.bin
    gst_all_1.gstreamer.out
    gst_all_1.gst-plugins-base
    (gst_all_1.gst-plugins-good.override { raspiCameraSupport = true; })
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
      # GPS time from ntpd_driver ROS node. Owned by root:root so we have to
      # make it world writable to allow ntpd_driver to write to it. Transmission
      # delays usually cause it to be ~60-80 ms off NTP time (no idea if this
      # will stay constant over time)
      refclock SHM 0:perm=0666 delay 0.5 offset 0.070 refid GPS

      # Allow GPS to step clock
      makestep 30 3
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
      image_dir=$(mktemp -d /var/lib/camera/still-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)
      chmod +rx "$image_dir"
      ${pkgs.libraspberrypi}/bin/raspistill \
        --timeout 0 \
        --timelapse 2000 \
        --rotation 180
        -o "$image_dir/img_%04d.jpg"
    '';
  };

  systemd.services.camera-video = {
    description = "Camera video capture";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      StateDirectory = "camera";
      StateDirectoryMode = "0755";

      ExecStart = pkgs.runCommand "camera-video.sh" {
        text = ''
          #!${pkgs.runtimeShell}
          export GST_PLUGIN_SYSTEM_PATH_1_0="@gstPluginSystemPath@"
          image_dir=$(mktemp -d /var/lib/camera/video-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX)
          chmod +rx "$image_dir"

          ${pkgs.gst_all_1.gstreamer.bin}/bin/gst-launch-1.0 -e \
            rpicamsrc rotation=180 ! \
            video/x-h264,width=1920,height=1080,framerate=30/1,profile=high ! \
            queue ! \
            h264parse ! \
            matroskamux streamable=true ! \
            filesink location="$image_dir/video.mkv"
        '';
        passAsFile = [ "text" ];
        buildInputs = with pkgs.gst_all_1; [
          gstreamer
          gst-plugins-base
          (gst-plugins-good.override { raspiCameraSupport = true; })
          gst-plugins-bad
        ];
        preferLocalBuild = true;
      } ''
        export gstPluginSystemPath="$GST_PLUGIN_SYSTEM_PATH_1_0"
        substituteAll "$textPath" "$out"
        chmod +x "$out"
      '';
    };
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
      mavros
      fws-mavros
    ];

    launchFiles.mavros = {
      package = "fws_mavros";
      launchFile = "mavros.launch";
      args = {
        fcu_url = "/dev/ttyAMA0:921600";
        gcs_url = "udp://@";
      };
    };

    nodes = {
      ntpd-driver = {
        package = "ntpd_driver";
        node = "shm_driver";
        params = {
          shm_unit = "0";
          time_ref_topic = "/mavros/time_reference";
        };
      };
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
