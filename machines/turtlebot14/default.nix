{ lib, config, pkgs, secrets, ... }@args:

import ../turtlebot {
  id = 2;
  hostName = "turtlebot14";
  bootPartitionID = "0xa6e0c400";
  rootPartitionUUID = "c29aad76-7992-11e9-84cc-272a6ae7743e";
} args
