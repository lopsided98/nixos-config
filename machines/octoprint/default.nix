{ lib, config, pkgs, secrets, ... }: 
with lib;
let
  videoDevice = "/dev/v4l/by-id/usb-046d_HD_Webcam_C525_6498ABA0-video-index0";
  videoSystemdDevice = "dev-v4l-by\\x2did-usb\\x2d046d_HD_Webcam_C525_6498ABA0\\x2dvideo\\x2dindex0.device";
in {
  imports = [ ../../modules ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d0e35017-a677-4c46-818a-2ec028bb15a8";
    fsType = "ext4";
  };

  hardware.deviceTree = {
    filter = "meson-gxbb-odroidc2.dtb";
    overlays = [ {
      name = "bme280";
      dtsFile = ./bme280.dts;
    } ];
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible = {
      enable = true;
      copyKernels = false;
    };
  };

  # This patch could maybe fix the USB reset issue?
  # Bug reference: https://lore.kernel.org/lkml/ZMrFb7H1ynwwBSCA@Dell-Inspiron-15/T/#t
  boot.kernelPatches = [ {
    name = "arm64-dts-amlogic-gxbb-odroidc2-fix-invalid-reset-gpio-property";
    patch = pkgs.fetchpatch {
      url = "https://github.com/torvalds/linux/commit/e822ce43968daf9da4368617d2c948c22ccf93f9.patch";
      hash = "sha256-D7sL1wmCcJ5+co+NXZsjUOt+2TqQr3DmvFLRNxf0Dws=";
    };
  } ];

  hardware.enableRedistributableFirmware = true;
  local.networking = {
    wireless.home = {
      enable = true;
      interfaces = [ "wlu1u2" ];
    };
    home.interfaces.end0 = {};
  };
  systemd.network.wait-online.anyInterface = true;

  networking.hostName = "octoprint";

  # List services that you want to enable:

  services.octoprint = {
    enable = true;
    port = 80;
    extraConfig.webcam = {
      snapshot = "http://localhost:5050?action=snapshot";
      stream = "http://octoprint.local:5050?action=stream";
    };
    plugins = let
      python = pkgs.octoprint.python;

      octoprint-filament-sensor-universal = python.pkgs.buildPythonPackage rec {
        pname = "OctoPrint-Filament-Sensor-Universal";
        version = "2.0.0";
        format = "setuptools";

        src = pkgs.fetchFromGitHub {
          owner = "lopsided98";
          repo = pname;
          rev = "78a89d74b0b0fadcade0b4d20b43d1f496c44e3f";
          hash = "sha256-KocqarKWX9WvZidmTqzTodX3hP3EcYpRWHrOW/2LB5I=";
        };

        # No tests
        doCheck = false;

        propagatedBuildInputs = [ pkgs.octoprint python.pkgs.libgpiod ];
      };

      octoprint-portlister = with python.pkgs; let
        inotify = buildPythonPackage rec {
          pname = "inotify";
          version = "unstable-2020-08-26";

          src = pkgs.fetchFromGitHub {
            owner = "dsoprea";
            repo = "PyInotify";
            rev = "f77596ae965e47124f38d7bd6587365924dcd8f7";
            sha256 = "0mvddr5jlw7pql2mw9mcg3c9n5k4kp2b7yk7nqzaiz2irpi2wj2z";
          };

          # Tests fail for non-obvious reasons
          doCheck = false;

          checkInputs = [ nose ];
        };
      in buildPythonPackage rec {
        pname = "OctoPrint-PortLister";
        version = "0.1.10";

        src = pkgs.fetchFromGitHub {
          owner = "markwal";
          repo = pname;
          rev = version;
          sha256 = "1i5kh8v99357ia4ngq3llap8kw6fkk1j91s27jfb1adgxycxpsqv";
        };

        # No tests
        doCheck = false;

        propagatedBuildInputs = [ pkgs.octoprint inotify ];
      };
    in p: [ octoprint-filament-sensor-universal octoprint-portlister ];
  };
  # Allow binding to port 80
  systemd.services.octoprint.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

  # Allow access to printer serial port and GPIO
  users.users.${config.services.octoprint.user}.extraGroups = [ "dialout" "gpio" ];

  services.mjpg-streamer = {
    enable = true;
    inputPlugin = "input_uvc.so -d ${videoDevice} -r 1280x720";
  };
  # Automatically start mjpg-streamer when camera connected (and stop when removed)
  systemd.services.mjpg-streamer = {
    after = [ videoSystemdDevice ];
    bindsTo = [ videoSystemdDevice ];
    # Replace multi-user.target
    wantedBy = lib.mkForce [ videoSystemdDevice ];
  };

  users.groups.gpio = { };
  services.udev.extraRules = ''
    # Enable systemd device units for cameras
    SUBSYSTEM=="video4linux", TAG+="systemd"
    # Allow gpio group to access GPIO devices
    KERNEL=="gpiochip*", GROUP="gpio", MODE="0660"
  '';

  # BME280 data logging to InfluxDB
  local.services.telegraf = {
    enable = true;
    enableSystemMetrics = false;
    influxdb = {
      tlsCertificate = ./telegraf/influxdb.pem;
      tlsKeySecret = secrets.octoprint.telegraf.influxdbTlsKey;
    };
  };
  services.telegraf.extraConfig = {
    outputs.influxdb = {
      database_tag = "database";
      exclude_database_tag = true;
    };
    inputs.multifile = {
      name_override = "bme280";
      tags.database = "radon";
      interval = "5m";
      base_dir = "/sys/bus/i2c/devices/0-0077/iio:device1";
      file = [
        {
          file = "in_pressure_input";
          dest = "pressure";
          conversion = "float";
        }
        {
          file = "in_temp_input";
          dest = "temperature";
          conversion = "float(3)";
        }
        {
          file = "in_humidityrelative_input";
          dest = "humidityrelative";
          conversion = "float(3)";
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [
    80 # OctoPrint
    5050 # mjpg-streamer
  ];

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
