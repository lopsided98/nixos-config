{ lib, config, pkgs, secrets, ... }@args:

import ../turtlebot {
  id = 1;
  hostName = "turtlebot12";
  bootPartitionID = "0xaa703e3b";
  rootPartitionUUID = "9592c7e6-7992-11e9-a59a-f7b56d0ff52e";
} args
