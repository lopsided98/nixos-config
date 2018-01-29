{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    extraOptions = "--dns 8.8.8.8";
  };

}
