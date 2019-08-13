{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder6";
  firmwarePartitionID = "0x15be3e0d";
  rootPartitionUUID = "ff20c0df-80a0-4fc3-8b6a-de04a669a438";
} args
