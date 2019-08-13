{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder7";
  firmwarePartitionID = "0xf8bc5774";
  rootPartitionUUID = "b9583f35-5ccb-4065-a8df-3bf2df3f3ac8";
} args
