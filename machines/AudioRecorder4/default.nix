{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder4";
  bootPartitionID = "0x3ec4cb09";
  rootPartitionUUID = "776b789a-87c9-4b34-b35f-8bd1e3860f0c";
} args
