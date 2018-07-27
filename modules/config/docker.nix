{ config, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    # Use latest version of Docker
    package = pkgs.docker-edge;
    extraOptions = "--dns 192.168.1.2";
  };

}
