{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder8";
  firmwarePartitionID = "0x03e17b02";
  rootPartitionUUID = "d74fce88-cc2c-4d21-85fa-b5a4fecf98fb";
} args
