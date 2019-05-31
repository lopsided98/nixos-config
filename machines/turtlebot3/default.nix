{ lib, config, pkgs, secrets, ... }@args:

import ../turtlebot {
  id = 3;
  bootPartitionID = "0x428700d0";
  rootPartitionUUID = "f57df5a9-1f89-4537-b31d-d431a407a206";
} args
