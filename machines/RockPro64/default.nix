# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }: let
  interface = "eth0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/config/telegraf.nix

    ../../modules
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    #kernelParams = [ "earlycon=uart8250,mmio32,0xff130000 coherent_pool=1M ethaddr=\${ethaddr} eth1addr=\${eth1addr} serial=\${serial#}" ];
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rock64_mainline;
  };

  # Workaround checksumming bug
  networking.localCommands = ''
    ${pkgs.ethtool}/bin/ethtool -K eth0 rx off tx off
  '';

  systemd.network = {
    enable = true;
    networks."${interface}" = {
      name = interface;
      # DHCP=v4
      address = [ "192.168.1.7/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "RockPro64"; # Define your hostname.
  networking.hostId = "67b35626";

  environment.systemPackages = with pkgs; [
  ];

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [4247];

  # Enable SD card TRIM
  services.fstrim.enable = true;
}
