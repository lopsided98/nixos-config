{ lib, config, pkgs, ... }: let
  videoDevice = "/dev/v4l/by-id/usb-046d_HD_Webcam_C525_6498ABA0-video-index0";
  videoSystemdDevice = "dev-v4l-by\\x2did-usb\\x2d046d_HD_Webcam_C525_6498ABA0\\x2dvideo\\x2dindex0.device";
in {
  imports = [ ../../modules ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d0e35017-a677-4c46-818a-2ec028bb15a8";
    fsType = "ext4";
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  hardware.enableRedistributableFirmware = true;
  local.networking = {
    wireless.home = {
      enable = true;
      interface = "wlan0";
    };
    home = {
      enable = true;
      interfaces = [ "eth0" ];
    };
  };

  networking.hostName = "octoprint";

  # List services that you want to enable:

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

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
        version = "1.0.0";

        src = pkgs.fetchFromGitHub {
          owner = "lopsided98";
          repo = pname;
          rev = "8a72696867a9a008c5a79b49a9b029a4fc426720";
          sha256 = "1a7lzmjbwx47qhrkjp3hggiwnx172x4axcz0labm9by17zxlsimr";
        };

        propagatedBuildInputs = [ pkgs.octoprint python.pkgs.libgpiod ];
      };
    in p: [ octoprint-filament-sensor-universal ];
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

  networking.firewall.allowedTCPPorts = [
    80 # OctoPrint
    5050 # mjpg-streamer
  ];

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
