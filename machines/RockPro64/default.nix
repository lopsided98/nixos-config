{ lib, config, pkgs, secrets, ... }:

with lib;

let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/config/telegraf.nix

    ../../modules
  ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-${interface}" = {
        name = interface;
        address = [ "192.168.1.7/24" ];
        gateway = [ "192.168.1.1" ];
        dns = [ "192.168.1.2" "2601:18a:0:ff60:ba27:ebff:fe5e:6b6e" ];
        dhcpConfig.UseDNS = false;
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };
    };
  };
  networking = {
    hostName = "RockPro64";
    hostId = "67b35626";
  };

  # List services that you want to enable:

  local.services.rtlamr.enable = true;

  # Use the same speed as the bootloader/early console
  services.getty.serialSpeed = [ 1500000 ];

  services.openssh = {
    ports = [ 4247 ];
    hostKeys = [
      { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.RockPro64.ssh.hostRsaKey; }
      { type = "ed25519"; path = secrets.getSecret secrets.RockPro64.ssh.hostEd25519Key; }
    ];
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  environment.secrets = mkMerge [
    (secrets.mkSecret secrets.RockPro64.ssh.hostRsaKey {})
    (secrets.mkSecret secrets.RockPro64.ssh.hostEd25519Key {})
  ];
}
