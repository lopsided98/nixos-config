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
    version = 4;
    enableWirelessFirmware = true;
  };
  #local.profiles.headless = true;

  sdImage = {
    firmwarePartitionID = "0x38cd60d2";
    rootPartitionUUID = "4f54d50c-b6fb-4917-8e06-e008469bbb37";
    compressImage = false;
  };

  boot.kernelPackages = mkForce pkgs.linuxPackages_rpi4;

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
    /*{
      name = "sph0645lm4h-microphone";
      dtsFile = ./sph0645lm4h-microphone.dts;
    }*/
  ];

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
    /*v4l-utils
    gst_all_1.gstreamer.bin
    gst_all_1.gstreamer.out
    gst_all_1.gst-plugins-base
    (gst_all_1.gst-plugins-good.override { raspiCameraSupport = true; })*/
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
    package = pkgs.chrony.overrideAttrs ({
      patches ? [], ...
    }: {
      patches = patches ++ [
        # Support 64-bit time_t in SOCK reflock messages
        (pkgs.fetchpatch {
          url = "https://git.tuxfamily.org/chrony/chrony.git/patch/refclock_sock.c?id=badaa83c319ae5a0bef872d1e7a55bf1260c1b84";
          hash = "sha256-vzswMb4W16h4tYJSyYmj7ah9JabF9v/V9FvP37B6qz8=";
        })
      ];
    });
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
      ${pkgs.libraspberrypi}/bin/raspistill \
        --timeout 0 \
        --timelapse 2000 \
        --rotation 180
        -o "$image_dir/img_%04d.jpg"
    '';
  };

  sound.enable = true;
  /*systemd.services.camera-video = {
    description = "Camera video capture";
    bindsTo = [ "dev-vchiq.device" ];
    after = [ "dev-vchiq.device" ];
    # wantedBy = [ "dev-vchiq.device" ];
    serviceConfig = {
      Type = "exec";
      Restart = "on-failure";
      StateDirectory = "camera";
      StateDirectoryMode = "0755";

      ExecStart = pkgs.runCommand "camera-video.sh" {
        text = ''
          #!${pkgs.runtimeShell}
          export GST_PLUGIN_SYSTEM_PATH_1_0="@gstPluginSystemPath@"
          image_dir=$(mktemp -d /var/lib/camera/video_$(date +%Y%m%d_%H%M%S)_XXXX)
          chmod +rx "$image_dir"

          ${pkgs.gst_all_1.gstreamer.bin}/bin/gst-launch-1.0 -e \
            rpicamsrc rotation=180 ! \
            video/x-h264,width=1920,height=1080,framerate=30/1,profile=high ! \
            queue ! \
            h264parse ! \
            matroskamux ! \
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
  };*/

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
