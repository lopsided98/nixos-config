{ lib, config, pkgs, secrets, ... }: 
with lib;
let
  printerPowerCommand = name: method: let
    curl = lib.getExe pkgs.curl;
    netrc = secrets.getSystemdSecret "printer-power-netrc" secrets.octoprint.printerPowerNetrc;
  in "'${curl}' --silent --show-error --netrc-file '${netrc}' -X POST http://printer-power.local/switch/${name}/${method}";
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

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        copyKernels = false;
      };
    };

    initrd.availableKernelModules = [
      # SD card
      "mmc_block"
    ];

    # This driver controls the onboard USB hub reset line, but somehow this
    # doesn't work right. As soon as this driver is loaded, all the USB devices
    # disconnect.
    # See: https://lore.kernel.org/lkml/ZMrFb7H1ynwwBSCA@Dell-Inspiron-15/T/#t
    blacklistedKernelModules = [ "onboard-usb-dev" ];
  };

  hardware.firmware = [
    (pkgs.runCommand "rt2870-firmware" {} ''
      mkdir -p "$out/lib/firmware"
      cp '${pkgs.linux-firmware}'/lib/firmware/rt2870.bin "$out/lib/firmware"
    '')
  ];
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
    extraConfig.plugins = {
      classicwebcam = {
        snapshot = "http://localhost:5050/snapshot";
        stream = "http://octoprint.local:5050/stream";
      };

      psucontrol = {
        switchingMethod = "SYSTEM";
        onSysCommand = printerPowerCommand "printer" "turn_on";
        offSysCommand = printerPowerCommand "printer" "turn_off";
      };
    };
    plugins = let
      python = pkgs.octoprint.python;

      octoprint-filament-sensor-universal = python.pkgs.buildPythonPackage rec {
        pname = "OctoPrint-Filament-Sensor-Universal";
        version = "2.0.0";

        pyproject = true;
        build-system = [ python.pkgs.setuptools ];

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

      octoprint-portlister = python.pkgs.buildPythonPackage rec {
        pname = "OctoPrint-PortLister";
        version = "0.1.10";

        pyproject = true;
        build-system = [ python.pkgs.setuptools ];

        src = pkgs.fetchFromGitHub {
          owner = "markwal";
          repo = pname;
          rev = version;
          sha256 = "1i5kh8v99357ia4ngq3llap8kw6fkk1j91s27jfb1adgxycxpsqv";
        };

        # No tests
        doCheck = false;

        propagatedBuildInputs = [ pkgs.octoprint python.pkgs.inotify ];
      };
    in plugins: with plugins; [ octoprint-filament-sensor-universal octoprint-portlister psucontrol ];
  };
  # Allow binding to port 80
  systemd.services.octoprint.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

  # Allow access to printer serial port and GPIO and printer power outlet
  users.users.${config.services.octoprint.user}.extraGroups = [ "dialout" "gpio" "printer-power" ];

  users.groups.gpio = { };
  services.udev.extraRules = ''
    # Allow gpio group to access GPIO devices
    KERNEL=="gpiochip*", GROUP="gpio", MODE="0660"
  '';

  services.ustreamer = {
    enable = true;
    autoStart = false;
    device = "/dev/v4l/by-id/usb-046d_HD_Webcam_C525_6498ABA0-video-index0";
    listenAddress = "[::]:5050";
    extraArgs = [ "--resolution=1280x720" ];
  };

  systemd.services.camera-light = {
    description = "Control 3D printer camera lighting";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      DynamicUser = true;
      SupplementaryGroups = [ "printer-power" ];
      Restart = "on-failure";
      RestartSec = 10;
      ExecStart = printerPowerCommand "light" "turn_on";
      ExecStop = printerPowerCommand "light" "turn_off";
    };
    # Allow unlimited restarts
    unitConfig.StartLimitIntervalSec = 0;
    wantedBy = [ "ustreamer.service" ];
    bindsTo = [ "ustreamer.service" ];
  };

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
    5050 # ustreamer
  ];

  # Enable SD card TRIM
  services.fstrim.enable = true;

  # Group that can access the credentials to control the printer power outlet
  users.groups.printer-power = { };

  systemd.secrets.printer-power-netrc = {
    files = secrets.mkSecret secrets.octoprint.printerPowerNetrc {
      user = "root";
      group = "printer-power";
      mode = "0440";
    };
    units = [ "octoprint.service" ];
  };
}
