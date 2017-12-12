# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }: let
  interface = "eth0";
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/common.nix
      ../../modules/services/networking/dnsupdate.nix
#      ../../modules/docker.nix
      ../../modules/services/continuous-integration/aur-buildbot/worker.nix
    ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
  };

  systemd.network = {
    enable = true;
    networks."${interface}" = {
      name = interface;
      address = [ "192.168.1.3/24" ];
      gateway = [ "192.168.1.1" ];
      dns = [ "192.168.1.2" "2601:18a:0:7829:a0ad:20ff:fe40:7a1c" ];
    };
  };
  networking.hostName = "ODROID-XU4"; # Define your hostname.

  # Use ARM binary cache
  nix.binaryCaches = lib.mkForce [ "http://nixos-arm.dezgeg.me/channel" ];
  nix.binaryCachePublicKeys = [ "nixos-arm.dezgeg.me-1:xBaUKS3n17BZPKeyxL4JfbTqECsT+ysbDJz29kLFRW0=%" ];
  
  environment.systemPackages = with pkgs; [
    pkgs.linuxPackages_latest.tmon
  ];
  
  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [4243];
  
#  services.aur-buildbot-worker = {
#    enable = true;
#    workerPass = "xZdKI5whiX5MNSfWcAJ799Krhq5BZhfe11zBdamx";
#    masterHost = "hp-z420.nsupdate.info";
#  };
  
  services.dnsupdate = {
    enable = true;
    addressProvider = {
      ipv4.type = "Web";
    };
    
    dnsServices = [ {
      type = "GoogleDomains";
      args = {
        hostname = "odroid-xu4.benwolsieffer.com";
        username = "jPniAhcATuQPmThZ";
        password = "7DNMvRSY5eq5ypSG";
      };
    } ];
  };

  
  # Enable SD card TRIM
  services.fstrim.enable = true;
}
