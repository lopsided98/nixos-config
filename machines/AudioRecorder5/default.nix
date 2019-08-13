{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder5";
  firmwarePartitionID = "0xaa9760f1";
  rootPartitionUUID = "c5dfd661-992a-431b-9a1d-dde7d2e92ed3";
} args
