{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder2";
  firmwarePartitionID = "0x536b6126";
  rootPartitionUUID = "01126b39-7d63-4a89-a9da-7a307cff836b";
} args
