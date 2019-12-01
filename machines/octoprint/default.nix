{ lib, config, pkgs, ... }: {
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
  local.networking.wireless.home = {
    enable = true;
    interface = "wlan0";
  };

  systemd.network = {
    enable = true;
    networks."30-eth0" = {
      name = "eth0";
      DHCP = "v4";
      dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
      dhcpConfig.UseDNS = false;
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
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
  };
  # Allow binding to port 80
  systemd.services.octoprint.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

  # Allow access to printer serial port
  users.users.${config.services.octoprint.user}.extraGroups = [ "dialout" ];

  services.mjpg-streamer = {
    enable = true;
    inputPlugin = "input_uvc.so -r 1280x720";
  };

  networking.firewall.allowedTCPPorts = [
    80 # OctoPrint
    5050 # mjpg-streamer
  ];

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
