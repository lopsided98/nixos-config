{ lib, config, pkgs, ... }: {
  imports = [ ../../modules ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/b63c2f4a-e1a2-41d3-9ca3-c96f0ba8ef6a";
    fsType = "ext4";
  };

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelParams = [ "ethaddr=\${ethaddr}" ];
  };

  systemd.network = {
    enable = true;
    networks."30-eth0" = {
      name = "eth0";
      DHCP = "v4";
    };
  };
  networking.hostName = "zybo-z7";

  # List services that you want to enable:

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
