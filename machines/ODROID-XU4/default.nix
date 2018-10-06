# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }: let
  interface = "br0";
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    
    # Modules without configuration options
    ../../modules/config/telegraf.nix
    ../../modules/config/openvpn/server.nix
    
    ../../modules
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_hardkernel_4_14;
  };

  systemd.network = {
    enable = true;
    networks."${interface}" = {
      name = interface;
      address = [ "192.168.1.3/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
      extraConfig = ''
        [IPv6AcceptRA]
        UseDNS=no
      '';
    };
  };
  networking.hostName = "ODROID-XU4"; # Define your hostname.

  nix.extraOptions = ''
    extra-platforms = armv6l-linux
  '';
  
  environment.systemPackages = with pkgs; [
    pkgs.linuxPackages_latest.tmon
  ];
  
  # List services that you want to enable:

  # Serial terminal
  systemd.services."getty@ttySAC2".enable = true;

  # Set SSH port
  services.openssh.ports = [4243];

  # Temperature monitoring
  services.telegraf.inputs.sensors = {
    remove_numbers = true;
  };
  # Register TMP102 at boot
  systemd.services.tmp102 = {
    description = "Register TMP102 as I2C device";
    serviceConfig.Type = "oneshot";
    wantedBy = [ "telegraf.service" ];
    script = "echo tmp102 0x48 > /sys/class/i2c-adapter/i2c-1/new_device";
    unitConfig.ConditionPathExists = "!/sys/class/i2c-adapter/i2c-1/1-0048";
  };
  # Add lm_sensors for temperature monitoring
  systemd.services.telegraf.path = [ pkgs.lm_sensors ];
  
  # Enable SD card TRIM
  services.fstrim.enable = true;
}
