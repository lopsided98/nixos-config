{ lib, config, pkgs, secrets, ... }@args:

import ../AudioRecorder {
  hostName = "AudioRecorder1";
  ap = true;
  bootPartitionID = "0x33d34b3b";
  rootPartitionUUID = "a96e868e-8f68-4db0-a6ce-8143df524550";
} args
