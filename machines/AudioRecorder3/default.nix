{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder3";
  bootPartitionID = "0x115ea710";
  rootPartitionUUID = "91714007-729e-41c0-a3f6-f4d800a5710a";
} args
