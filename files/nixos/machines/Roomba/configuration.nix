# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ lib, config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/common.nix
      ../../modules/ssh.nix
    ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    kernelParams = [ "cma=32M" ];
    kernelPackages = lib.mkForce pkgs.linuxPackages_4_13;
  };

  systemd.network = {
    enable = true;
    networks.eth0 = {
      name = "eth0";
      DHCP = "v4";
      dhcpConfig.UseDNS = false;
      dns = ["192.168.1.2"];
    };
  };
  networking.hostName = "Roomba"; # Define your hostname.
  
  environment.systemPackages = with pkgs; with rosPackages; [
  ];
  
  # List services that you want to enable:

  # Set SSH port
  services.openssh.ports = [22];
  
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
  
  # Enable SD card TRIM
  services.fstrim.enable = true;

  # Override OpenBLAS to support aarch64
  nixpkgs.config.packageOverrides = pkgs: rec {
    openblas = pkgs.openblas.overrideAttrs (oldAttrs: rec {
      makeFlags =
        [
          "FC=gfortran"
          "PREFIX=\"$(out)\""
          "NUM_THREADS=64"
          "INTERFACE64=0"
          "NO_STATIC=1"
          "BINARY=64"
          "TARGET=ARMV8"
          "DYNAMIC_ARCH=0"
          "CC=gcc"
          "USE_OPENMP=1"
        ];
    });
  };
}
