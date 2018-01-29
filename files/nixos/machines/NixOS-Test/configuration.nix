# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/common.nix
      ../../modules/services/web-apps/muximux.nix
      ../../modules/docker.nix
      ../../modules/nginx.nix
    ];
    
  nix.useSandbox = lib.mkForce false;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  services.fstrim.enable = true;

  systemd.network = {
    enable = true;
    networks.ens3 = {
      name = "ens3";
      address = ["172.21.42.4"];
      gateway = ["172.21.42.1"];
      dns = ["192.168.1.2"];
    };
  };
  networking.hostName = "NixOS-Test";
  networking.extraHosts = ''
    192.168.1.3 odroid-xu4.benwolsieffer.com
    192.168.1.4 dell-optiplex-780.benwolsieffer.com
  '';

  environment.systemPackages = with pkgs; with rosPackages; [
  ];

  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [4247];
  
  # Configure Muximux
  #services.muximux.enable = true;
  #services.nginx.virtualHosts.muximux = {
  #  serverName = ''"\"'';
  #  listen = [{addr = "0.0.0.0"; port = 81;}];
  #};
  #networking.firewall.allowedTCPPorts = [81];
}

