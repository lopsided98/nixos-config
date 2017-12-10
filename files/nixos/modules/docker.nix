{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    extraOptions = "--dns 192.168.1.2";
  };

}
